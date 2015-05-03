#!/bin/sh

echo "npm install project"
npm install # fetches electron-prebuilt

echo "npm install app"
export npm_config_disturl=https://atom.io/download/atom-shell
export npm_config_target=0.23.0
export npm_config_arch=x64
(cd app && HOME=~/.electron-gyp npm install --silent)

echo "remove previous"
rm -rf output/Yakayak.app
echo "copy Electron.app -> Yakayak.app"
cp -R node_modules/electron-prebuilt/dist/Electron.app output/Yakayak.app
echo "copy app -> output/Yakayak.app/Contents/Resources"
cp -R app output/Yakayak.app/Contents/Resources
