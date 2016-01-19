#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

ROOT=$(dirname "${BASH_SOURCE}")

function yakyak::package() {
  local arch="$1"
  local src="electron"
  local dest="yakyak"

  if [[ ! -d "$arch" ]]; then
    echo "Skipping packaging for $arch (source dist not found)"
    return
  fi

  if [[ "$arch" =~ win32 ]]; then
    src="${src}.exe"
    dest="${dest}.exe"
  fi

  pushd $arch >/dev/null
    mv $src $dest
    cp -R ../../app resources/app
  popd >/dev/null
  zip -r yakyak-$arch.zip $arch
}

for dep in curl unzip sed; do
  echo "checking dependency... $dep"
  test ! $(which $dep) && echo "ERROR: missing $dep" && exit 1
done

ELECTRON_VERSION=$(npm list --depth=0 |grep electron-prebuilt | cut -f2 -d@)
VERSION=$(node -e "console.log(require('./package').version)")
DEFAULT_PLATFORMS=("darwin-x64" "linux-ia32" "linux-x64" "win32-ia32" "win32-x64")
PLATFORMS=${PLATFORMS:-$DEFAULT_PLATFORMS}

mkdir -p dist
cd dist
for PLATFORM in ${PLATFORMS[*]}; do
    rm -rf $PLATFORM
    echo "https://github.com/atom/electron/releases/download/v$ELECTRON_VERSION/electron-v$ELECTRON_VERSION-$PLATFORM.zip"
    test ! -f electron-v$ELECTRON_VERSION-$PLATFORM.zip && \
    curl -LO https://github.com/atom/electron/releases/download/v$ELECTRON_VERSION/electron-v$ELECTRON_VERSION-$PLATFORM.zip
    unzip -o electron-v$ELECTRON_VERSION-$PLATFORM.zip -d $PLATFORM
done

if [ -d darwin-x64 ]; then
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
fi

yakyak::package win32-x64
yakyak::package win32-ia32
yakyak::package linux-x64
yakyak::package linux-ia32
yakyak::package darwin-x64

cd ..
