#
#   SWIFT: 6.0 - MACOS: 15.7
#   NoLet - translate.py
#
#   Author:        Copyright (c) 2024 QingHe. All rights reserved.
#   Document:      https://wiki.wzs.app
#   E-mail:        to@wzs.app

#   Description:

#   History:
#    Created by Neo on 2025/11/22 16:50.
    
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Requires Python 3.10+ for async/await syntax

import os
import json
import asyncio
from openai import AsyncOpenAI

deepseek_key = os.getenv("DEEPSEEK_KEY")

if deepseek_key is None:
    exit("You need to set DEEPSEEK_KEY environment variable")

client = AsyncOpenAI(base_url="https://api.deepseek.com", api_key=deepseek_key)

# 并发限制数量
semaphore = asyncio.Semaphore(10)


async def translate_deepseek(datas, target_language="en"):
    messages = [
        {
            "role": "system",
            "content": "You are an app localization translation assistant. Give the text, and directly return the translation without extra words. The translation language code is:" + target_language
        },
        {"role": "user", "content": json.dumps(datas)},
    ]

    async with semaphore:
        completion = await client.chat.completions.create(
            model="deepseek-chat",
            messages=messages
        )
        response = completion.choices[0].message.content.strip('"')
        return response


async def trans_main(target_language="en", json_file=None):
    if json_file is None:
        json_file = "./Localizable.xcstrings"

    with open(json_file, "r", encoding="utf-8") as fs:
        data = json.load(fs)

    results = data.get("strings", {})
    all_count = len(results)
    print(all_count, " pending processing were found")

    tasks = []
    for key in results:
        task = asyncio.create_task(translate_deepseek(key, target_language=target_language))
        tasks.append((key, task))

    for count, (key, task) in enumerate(tasks, start=1):
        try:
            text = await task
            results[key]["localizations"][target_language] = {'stringUnit':{'state': 'translated', 'value': text}}
            print(f"No. {count}/{all_count} {key} -> {text}")
        except Exception as e:
            print(f"Failed to translate {key}: {e}")

    data["strings"] = results

    with open(json_file, "w+", encoding="utf-8") as fs:
        json.dump(data, fs, ensure_ascii=False, indent=2)


if __name__ == '__main__':
    asyncio.run(trans_main(target_language="tr", json_file="../NoLet/Localizable.xcstrings"))

