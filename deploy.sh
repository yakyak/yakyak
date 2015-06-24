#!/bin/bash

for dep in curl unzip sed; do
  echo "checking dependency... $dep"
  test ! $(which $dep) && echo "ERROR: missing $dep" && exit 1
done

ELECTRON_VERSION="0.28.1"
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
mv Electron.app Yakyak.app
sed -i.bak s/Electron/Yakyak/ Yakyak.app/Contents/Info.plist
sed -i.bak s/com\.github\.electron/com\.github\.yakyak/ Yakyak.app/Contents/Info.plist
mv Yakyak.app/Contents/MacOS/Electron Yakyak.app/Contents/MacOS/Yakyak
cp -R ../../app Yakyak.app/Contents/Resources/app
cp ../../src/icons/atom.icns Yakyak.app/Contents/Resources/atom.icns
zip -r ../yakyak-osx.app.zip Yakyak.app
cd ..

cd win32-ia32
mv electron.exe yakyak.exe
cp -R ../../app resources/app
cd ..
zip -r yakyak-win32-ia32.zip win32-ia32

cd linux-ia32
mv electron yakyak
cp -R ../../app resources/app
cd ..
zip -r yakyak-linux-ia32.zip linux-ia32

cd ..
