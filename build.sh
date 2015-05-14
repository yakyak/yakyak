#!/bin/sh

echo "npm install project"
npm install # fetches electron-prebuilt

echo "remove previous"
rm -rf output/Yakayak.app
echo "copy Electron.app -> Yakayak.app"
cp -R node_modules/electron-prebuilt/dist/Electron.app output/Yakayak.app

echo "brunch build"
./node_modules/.bin/brunch build

echo "npm install app"
export npm_config_disturl=https://atom.io/download/atom-shell
export npm_config_target=0.23.0
export npm_config_arch=x64
(cd output/Yakayak.app/Contents/Resources/app && HOME=~/.electron-gyp npm install --silent)
