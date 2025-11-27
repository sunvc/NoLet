# !/usr/bin/env python3
# -*- coding: utf-8 -*-
# Requires Python 3.10+ for async/await syntax
#
# pip3 install openai
#
# pip3 install asyncio
#


from openai import AsyncOpenAI
from asyncio import Semaphore
import asyncio
import json
import os
import re
import argparse

class Translate:
    mode:int = 0
    semaphore_number: int = 10
    deepseek_key: str = ""
    host: str = ""
    model: str = ""
    root_dir: str = "../"
    local_file:str = "Localizable.xcstrings"
    info_file: str = "InfoPlist.strings"
    lang_file: str = "project.pbxproj"
    screen_file: str = "LaunchScreen.strings"
    lang_keys:list[str] = []
    client: AsyncOpenAI = {}

    def __init__(self, host:str=None, model:str=None, key:str=None, root_dir:str=None, mode:int=0):
        parser = argparse.ArgumentParser(description="params parser")
        parser.add_argument("--path", type=str, default="../", help="pth")
        parser.add_argument("--key", type=str, default=None, help="key")
        parser.add_argument("--host", type=str, default="https://api.deepseek.com", help="host")
        parser.add_argument("--model", type=str, default="deepseek-chat", help="mode")
        parser.add_argument("--mode", type=int, default=0, help="mode")
        args = parser.parse_args()

        self.deepseek_key = (
            (args.key if args.key else None)
            or (key if key else None)
            or os.getenv("DEEPSEEK_KEY")
        )

        if not self.deepseek_key or len(self.deepseek_key) < 10:
            exit("DEEPSEEK_KEY not provided. Use --key, constructor key=..., or set environment variable.")

        if host is None:
            self.host = args.host
        else:
            self.host = host

        if model is None:
            self.model = args.model
        else:
            self.model = model

        if root_dir is None:
            self.root_dir = args.path
        else:
            self.root_dir = root_dir

        if mode > 0:
            self.mode = mode
        else:
            self.mode = args.mode

        self.client = AsyncOpenAI(base_url=self.host, api_key=self.deepseek_key)


    async def translate_deepseek(self, datas, system_message, semaphore: Semaphore, is_json=False):
        messages = [
            {"role": "system", "content": system_message},
            {"role": "user", "content": json.dumps(datas) if is_json else datas}
        ]

        async with semaphore:
            completion = await self.client.chat.completions.create(
                model="deepseek-chat",
                messages=messages
            )
            response = completion.choices[0].message.content.strip('"')
            return response

    async def trans_main(self, target_language, json_file=None, is_json=False):
        semaphore = asyncio.Semaphore(self.semaphore_number)
        system_message = self.get_local_tips(target_language)
        if json_file is None:
            json_file = "./Localizable.xcstrings"

        with open(json_file, "r", encoding="utf-8") as fs:
            data = json.load(fs)

        results = data.get("strings", {})
        all_count = len(results)
        print(f"{target_language}/{all_count}", "pending processing were found")

        tasks = []
        skip_count = 0
        delete_keys = []

        for key in results:
            if results.get(key,{}).get("extractionState") == "stale":
                delete_keys.append(key)
                continue
            result_tem = results.get(key, {}).get("localizations", {}).get(target_language, None)

            if result_tem is None or result_tem.get("stringUnit", {}).get("value", "").strip() == "":
                task = asyncio.create_task(self.translate_deepseek(key, system_message, semaphore, is_json))
                tasks.append((key, task))
            else:
                result_value = result_tem.get("stringUnit", {}).get("value", "")
                skip_count += 1
                print(
                    f"\r Skip:{target_language} - {skip_count}/{all_count} - {key.split("\n")[0]} -> {result_value.split("\n")[0]}",
                    end="", flush=True)

        for count, (key, task) in enumerate(tasks, start=1):
            try:
                text = await task
                if results[key].get("localizations", None) is None:
                    results[key]["localizations"] = {}
                results[key]["localizations"][target_language] = {'stringUnit': {'state': 'translated', 'value': text}}
                print(f" {count}/{all_count} {key} -> {text}")
            except Exception as e:
                print(f"\nFailed to translate - {target_language} - {key}: {e}")

        for key in delete_keys:
            del results[key]
            print(f" {key} deleted")


        for key in results:
            localizations = results[key].get("localizations", {})
            localizations = {k: v for k, v in localizations.items() if k in self.lang_keys}
            results[key]["localizations"] = localizations

        data["strings"] = results

        with open(json_file, "w+", encoding="utf-8") as fs:
            json.dump(data, fs, ensure_ascii=False, indent=2)

    async def translate_other(self, json_files, file_type="InfoPlist.strings"):
        semaphore = asyncio.Semaphore(self.semaphore_number)
        results = {}
        for json_file in json_files:
            lang = os.path.basename(os.path.dirname(json_file)).replace(".lproj", "")
            tips = self.get_other_tips(file_type=file_type, lang_code=lang)
            with open(json_file, "r", encoding="utf-8") as fs:
                results[json_file] = {
                    "text": fs.read(),
                    "tips": tips,
                }
        tasks = []
        for key in results:
            task = asyncio.create_task(
                self.translate_deepseek(results[key]["text"], results[key]["tips"], semaphore, is_json=False))
            tasks.append((key, task))

        for count, (key, task) in enumerate(tasks, start=1):
            try:
                translate = await task
                results[key]["translate"] = translate
                print(f" {key} -> {translate}")
            except Exception as e:
                print(f"\nFailed to translate {key}: {e}")
        for item in results:
            translate_text = results[item]["translate"]
            if translate_text:
                with open(item, "w+", encoding="utf-8") as fs:
                    fs.write(translate_text)

    def find_localizable_files(self, file_name):
        result = []
        for dirpath, dirs, filenames in os.walk(self.root_dir):
            if file_name in filenames:
                full_path = os.path.join(dirpath, file_name)
                result.append(full_path)
        return result

    def find_langs(self):
        paths = self.find_localizable_files(self.lang_file)
        if len(paths) <= 0:
            print(f"No {self.lang_file} localizable files found")
            return []

        with open(paths[0], "r", encoding="utf-8") as f:
            content = f.read()
        match = re.search(r"knownRegions\s*=\s*\((.*?)\);", content, re.S)
        if match:
            regions_raw = match.group(1)
            regions = [r.strip().strip('"') for r in regions_raw.split(",") if
                       r.strip() and r.strip().strip('"') != "Base"]
            self.lang_keys = regions
            return regions
        return []

    @staticmethod
    def get_local_tips(lang_code = "en"):
       return f"You are an app localization translation assistant. After receiving the text, return the translation directly without extra words. If the text contains URL parameters (such as title, body, group, badge, default or parameter names like title=), do not translate them. The translation language code is: {lang_code}, and do not translate ‘无字书’, ‘無字書’ or ‘NoLet’."
    @staticmethod
    def get_other_tips(file_type, lang_code="en"):
        return f"Translate this Xcode {file_type} into {lang_code}, keep the format, return only the translation, and do not translate ‘无字书’, ‘無字書’ or ‘NoLet’."

    def localizable_handler(self):
        print("start handler:")
        langs = self.find_langs()
        # ------- Localizable.xcstrings  -------
        for lang_code in langs:
            paths = self.find_localizable_files(file_name=self.local_file)
            for path in paths:
                asyncio.run(self.trans_main( lang_code, json_file=path, is_json=True))


    def info_file_handler(self):
        print("start info_file handler:")
        # -------  InfoPlist.strings  ------
        paths = self.find_localizable_files(file_name=self.info_file)
        asyncio.run(self.translate_other(paths, file_type=self.info_file))

    def screen_file_handler(self):
        print("start screen_file handler:")
        # ------- LaunchScreen.strings  ------
        paths = self.find_localizable_files(file_name=self.screen_file)
        asyncio.run(self.translate_other(paths, file_type=self.screen_file))


    def run(self):
        # 0: Localizable.xcstrings  -------
        # 1:  InfoPlist.strings  ------
        # 2: LaunchScreen.strings  ------
        print("mode", self.mode)
        if self.mode == 0:
            self.localizable_handler()
            return
        elif self.mode == 1:
            self.info_file_handler()
            return
        elif self.mode == 2:
            self.screen_file_handler()
            return
        else:
            self.localizable_handler()
            self.info_file_handler()
            self.screen_file_handler()
            return


if __name__ == '__main__':

    Translate().run()

