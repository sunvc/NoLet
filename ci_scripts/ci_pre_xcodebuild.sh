#!/bin/sh

#  ci_pre_xcodebuild.sh
#  NoLet
#
#

if [[ $NOLET_BUILD_MODE = 'main' && $CI_XCODEBUILD_ACTION = 'archive' ]];
then
    echo "Setting NoLet Beta App Icon"
    APP_ICON_PATH=$CI_PRIMARY_REPOSITORY_PATH/NoLet/Assets.xcassets/AppIcon
    APP_LOGO_PATH=$CI_PRIMARY_REPOSITORY_PATH/NoLet/Assets.xcassets/logo
    
    # Remove existing App Icon
    rm -rf $APP_ICON_PATH
    rm -rf $APP_LOGO_PATH

    # Replace with NoLet Beta App Icon
    mv "$CI_PRIMARY_REPOSITORY_PATH/ci_scripts/$GITHUB_PROJECT_SAFE/AppIcon" "$APP_ICON_PATH"
    mv "$CI_PRIMARY_REPOSITORY_PATH/ci_scripts/$GITHUB_PROJECT_SAFE/logo" "$APP_LOGO_PATH"
fi

rm -rf $GITHUB_PROJECT_SAFE
