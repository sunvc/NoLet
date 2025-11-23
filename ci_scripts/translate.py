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

semaphore_number = 10

deepseek_key = os.getenv("DEEPSEEK_KEY")

if deepseek_key is None:
    exit("You need to set DEEPSEEK_KEY environment variable")

client = AsyncOpenAI(base_url="https://api.deepseek.com", api_key=deepseek_key)


async def translate_deepseek(datas, system_message, semaphore: Semaphore , is_json=False):
    messages = [
        {"role": "system", "content": system_message},
        {"role": "user", "content": json.dumps(datas) if is_json else datas}
    ]

    async with semaphore:
        completion = await client.chat.completions.create(
            model="deepseek-chat",
            messages=messages
        )
        response = completion.choices[0].message.content.strip('"')
        return response


async def trans_main(system_message, target_language, json_file=None, is_json=False):
    semaphore = asyncio.Semaphore(semaphore_number)
    if json_file is None:
        json_file = "./Localizable.xcstrings"

    with open(json_file, "r", encoding="utf-8") as fs:
        data = json.load(fs)

    results = data.get("strings", {})
    all_count = len(results)
    print(f"{target_language}/{all_count}", "pending processing were found")

    tasks = []
    skip_count = 0
    for key in results:
        result_tem = results.get(key,{}).get("localizations",{}).get(target_language, None)

        if result_tem is None or result_tem.get("stringUnit", {}).get("value", "").strip() == "":
            task = asyncio.create_task(translate_deepseek(key, system_message,semaphore, is_json))
            tasks.append((key, task))
        else:
            result_value = result_tem.get("stringUnit", {}).get("value", "")
            skip_count += 1
            print( f"\r Skip:{target_language} - {skip_count}/{all_count} - {key.split("\n")[0]} -> {result_value.split("\n")[0]}", end="", flush=True)


    if len(tasks) <= 0: return

    for count, (key, task) in enumerate(tasks, start=1):
        try:
            text = await task
            if results[key].get("localizations", None) is None:
                results[key]["localizations"] = {}
            results[key]["localizations"][target_language] = {'stringUnit': {'state': 'translated', 'value': text}}
            print(f" {count}/{all_count} {key} -> {text}")
        except Exception as e:
            print(f"\nFailed to translate - {target_language} - {key}: {e}")

    data["strings"] = results

    with open(json_file, "w+", encoding="utf-8") as fs:
        json.dump(data, fs, ensure_ascii=False, indent=2)


async def translate_other(json_files, file_type="InfoPlist.strings"):
    semaphore = asyncio.Semaphore(semaphore_number)
    results = {}
    for json_file in json_files:
        lang = os.path.basename(os.path.dirname(json_file)).replace(".lproj", "")
        tips = f"Translate this Xcode {file_type} into {lang}, keep the format, return only the translation, and do not translate ‘无字书’, ‘無字書’ or ‘NoLet’."
        with open(json_file, "r", encoding="utf-8") as fs:
            results[json_file] = {
                "text": fs.read(),
                "tips": tips,
            }
    tasks = []
    for key in results:
        task = asyncio.create_task(translate_deepseek(results[key]["text"], results[key]["tips"], semaphore, is_json=False))
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


def find_localizable_files(root_dir, file_name="Localizable.xcstrings"):
    result = []
    for dirpath, dirs, filenames in os.walk(root_dir):
        if file_name in filenames:
            full_path = os.path.join(dirpath, file_name)
            result.append(full_path)
    return result

def find_langs(root_item_dir, file_name="project.pbxproj"):
    paths = find_localizable_files(root_item_dir, file_name)
    if len(paths) <= 0:
        print(f"No {file_name}")
        return []

    with open(paths[0], "r", encoding="utf-8") as f:
        content = f.read()
    match = re.search(r"knownRegions\s*=\s*\((.*?)\);", content, re.S)
    if match:
        regions_raw = match.group(1)
        regions = [r.strip().strip('"') for r in regions_raw.split(",") if r.strip() and r.strip().strip('"') != "Base"]
        return regions
    return []


if __name__ == '__main__':
    print("start handler:")
    root_path = "../"
    langs = find_langs(root_path)
    # langs = ["en"]
    if len(langs) <= 0:
        exit("No localizable files found")
    print(langs)
    # ------- Localizable.xcstrings  -------
    for lang_code in langs:
        system_tips = f"You are an app localization translation assistant. After receiving the text, return the translation directly without extra words. If the text contains URL parameters (such as title, body, group, badge, default or parameter names like title=), do not translate them. The translation language code is: {lang_code}, and do not translate ‘无字书’, ‘無字書’ or ‘NoLet’."
        paths = find_localizable_files(root_dir=root_path, file_name="Localizable.xcstrings")
        for path in paths:
            asyncio.run(trans_main(system_tips, lang_code, json_file=path, is_json=True))

    # # -------  InfoPlist.strings  ------
    # paths = find_localizable_files(root_dir=root_path, file_name="InfoPlist.strings")
    # asyncio.run(translate_other(paths))
    #
    # # ------- LaunchScreen.strings  ------
    # paths = find_localizable_files(root_dir=root_path, file_name="LaunchScreen.strings")
    # asyncio.run(translate_other(paths))
