#!/bin/sh
echo "bundling OSX app"
rm -rf Yakayak.app
cp -R node_modules/electron-prebuilt/dist/Electron.app Yakayak.app
cp -R app Yakayak.app/Contents/Resources/app
cp -R node_modules Yakayak.app/Contents/Resources/app/
