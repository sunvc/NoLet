#!/bin/sh

# ci_post_clone.sh
# NoLet
# Created by Neo on 2025/9/7.


echo "=== 🚀 Starting CI Post Clone Script ==="

#----- 1. Clone Repository ----------------------------------------------------

REPO_URL="https://github.com/${GITHUB_NAME}/${GITHUB_PROJECT_SAFE}.git"

echo "Cloning repository: $REPO_URL"
git clone "$REPO_URL" || {
    echo "❌ Repository clone failed"
    exit 1
}

echo "✅ Repository cloned successfully"


#----- 2. Prepare Paths -------------------------------------------------------

APP_FILE_PATH="${CI_PRIMARY_REPOSITORY_PATH}/Publics/${SAFE_FILE_NAME}"
SRC_APP_FILE="${GITHUB_PROJECT_SAFE}/${SAFE_FILE_NAME}"

#----- 3. Remove Old Files ----------------------------------------------------

echo "Removing old target files..."
rm -f "$APP_FILE_PATH"


#----- 4. Move Files ----------------------------------------------------------

move_file() {
    local src=$1
    local dst=$2

    if [ ! -f "$src" ]; then
        echo "❌ Source file not found: $src"
        exit 1
    fi

    mv "$src" "$dst"

    if [ -f "$dst" ]; then
        echo "✅ File moved: ${src} → ${dst}"
    else
        echo "❌ Failed to move file: ${src}"
        exit 1
    fi
}

move_file "$SRC_APP_FILE"   "$APP_FILE_PATH"

#----- 5. Done ----------------------------------------------------------------

echo "=== 🎉 All operations completed successfully ==="
exit 0

