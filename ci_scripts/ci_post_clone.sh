#!/bin/sh

#  ci_post_clone.sh
#  NoLet
#
#  Created by lynn on 2025/9/7.
#  

git clone https://github.com/"$GITHUB_NAME"/"$GITHUB_PROJECT_SAFE".git

if [ -d "$GITHUB_PROJECT_SAFE" ]; then
    echo "Clone Success ✅"
else
    echo "Clone Fail ❌"
    exit 1
fi

APP_FILE_PATH="$CI_PRIMARY_REPOSITORY_PATH"/Publics/"$SAFE_FILE_NAME"

rm -rf "$APP_FILE_PATH"

mv "$GITHUB_PROJECT_SAFE"/"$SAFE_FILE_NAME" "$APP_FILE_PATH"


if [ -f "$APP_FILE_PATH" ]; then
    echo "MV Success ✅"
else
    echo "MV Fail ❌"
    exit 1
fi

