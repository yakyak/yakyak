#!/bin/bash

for dep in curl unzip sed; do
  echo "checking dependency... $dep"
  test ! $(which $dep) && echo "ERROR: missing $dep" && exit 1
done

ELECTRON_VERSION=$(npm list --depth=0 |grep electron-prebuilt | cut -f2 -d@)
VERSION=$(node -e "console.log(require('./package').version)")
PLATFORMS=("darwin-x64" "linux-ia32" "linux-x64" "win32-ia32" "win32-x64")

mkdir -p dist
cd dist
for PLATFORM in ${PLATFORMS[*]}; do
    rm -rf $PLATFORM
    echo "https://github.com/atom/electron/releases/download/v$ELECTRON_VERSION/electron-v$ELECTRON_VERSION-$PLATFORM.zip"
    test ! -f electron-v$ELECTRON_VERSION-$PLATFORM.zip && \
    curl -LO https://github.com/atom/electron/releases/download/v$ELECTRON_VERSION/electron-v$ELECTRON_VERSION-$PLATFORM.zip
    unzip -o electron-v$ELECTRON_VERSION-$PLATFORM.zip -d $PLATFORM
done

cd darwin-x64
mv Electron.app YakYak.app
defaults write $(pwd)/YakYak.app/Contents/Info.plist CFBundleDisplayName -string "YakYak"
defaults write $(pwd)/YakYak.app/Contents/Info.plist CFBundleExecutable -string "YakYak"
defaults write $(pwd)/YakYak.app/Contents/Info.plist CFBundleIdentifier -string "com.github.yakyak"
defaults write $(pwd)/YakYak.app/Contents/Info.plist CFBundleName -string "YakYak"
defaults write $(pwd)/YakYak.app/Contents/Info.plist CFBundleVersion -string "$VERSION"
plutil -convert xml1 $(pwd)/YakYak.app/Contents/Info.plist
mv YakYak.app/Contents/MacOS/Electron YakYak.app/Contents/MacOS/YakYak
cp -R ../../app YakYak.app/Contents/Resources/app
cp ../../src/icons/atom.icns YakYak.app/Contents/Resources/atom.icns
zip -r ../yakyak-osx.app.zip YakYak.app
cd ..

cd win32-ia32
mv electron.exe yakyak.exe
cp -R ../../app resources/app
cd ..
zip -r yakyak-win32-ia32.zip win32-ia32

cd win32-x64
mv electron.exe yakyak.exe
cp -R ../../app resources/app
cd ..
zip -r yakyak-win32-x64.zip win32-x64

cd linux-ia32
mv electron yakyak
cp -R ../../app resources/app
cd ..
zip -r yakyak-linux-ia32.zip linux-ia32

cd linux-x64
mv electron yakyak
cp -R ../../app resources/app
cd ..
zip -r yakyak-linux-x64.zip linux-x64

cd ..
