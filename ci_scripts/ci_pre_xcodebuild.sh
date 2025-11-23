#!/bin/sh

# ci_pre_xcodebuild.sh
# NoLet

set -e  # Exit immediately on error
set -u  # Treat undefined variables as errors

echo "=== 🚀 Starting Pre-XcodeBuild Script ==="

#----- 1. Check Conditions ----------------------------------------------------

if [[ "${NOLET_BUILD_MODE}" = "main" && "${CI_XCODEBUILD_ACTION}" = "archive" ]]; then
    echo "Setting NoLet Beta App Icon..."

    APP_ICON_PATH="${CI_PRIMARY_REPOSITORY_PATH}/NoLet/Assets.xcassets/AppIcon"
    APP_LOGO_PATH="${CI_PRIMARY_REPOSITORY_PATH}/NoLet/Assets.xcassets/logo"

    SRC_APP_ICON="${CI_PRIMARY_REPOSITORY_PATH}/ci_scripts/${GITHUB_PROJECT_SAFE}/AppIcon"
    SRC_APP_LOGO="${CI_PRIMARY_REPOSITORY_PATH}/ci_scripts/${GITHUB_PROJECT_SAFE}/logo"

    #----- 2. Remove existing icons ------------------------------------------
    echo "Removing existing App Icon and Logo..."
    rm -rf "${APP_ICON_PATH}" "${APP_LOGO_PATH}"

    #----- 3. Move new icon files --------------------------------------------
    move_file() {
        local src=$1
        local dst=$2

        if [ ! -d "$src" ] && [ ! -f "$src" ]; then
            echo "❌ Source not found: $src"
            exit 1
        fi

        mv "$src" "$dst"

        if [ -d "$dst" ] || [ -f "$dst" ]; then
            echo "✅ Moved: ${src} → ${dst}"
        else
            echo "❌ Failed to move ${src}"
            exit 1
        fi
    }

    move_file "$SRC_APP_ICON" "$APP_ICON_PATH"
    move_file "$SRC_APP_LOGO" "$APP_LOGO_PATH"

    echo "✅ NoLet Beta App Icon Set Successfully"
else
    echo "Skipping icon replacement (conditions not met)."
fi


#----- 4. Clean up cloned repo folder -----------------------------------------

echo "Cleaning temporary project folder..."
rm -rf "${GITHUB_PROJECT_SAFE}"

echo "=== 🎉 Pre-XcodeBuild Script Completed Successfully ==="
