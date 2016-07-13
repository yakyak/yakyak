#!/bin/bash


# Use -gt 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
# note: if this is set to -gt 0 the /etc/hosts part is not recognized ( may be a bug )

DARWIN_X64="darwin-x64"
LINUX_X64="linux-x64"
LINUX_IA32="linux-ia32"
WIN32_IA32="win32-ia32"
WIN32_X64="win32-x64"

ALLPLATFORMS=($DARWIN_X64 $LINUX_X64 $LINUX_IA32 $WIN32_IA32 $WIN32_X64)
PLATFORMS=()

if [[ $# -eq 0 ]]; then
  PLATFORMS=${ALLPLATFORMS[*]}
else
  while [[ $# -gt 0 ]]
  do
    key="$1"

    case $key in
      --darwin-x64)
        PLATFORMS=("${PLATFORMS[@]}" $DARWIN_X64)
        ;;
      --linux-x64)
        PLATFORMS=("${PLATFORMS[@]}" $LINUX_X64)
        ;;
      --linux-ia32)
        PLATFORMS=("${PLATFORMS[@]}" $LINUX_IA32)
        ;;
      --win32-x64)
        PLATFORMS=("${PLATFORMS[@]}" $WIN32_X64)
        ;;
      --win32-ia32)
        PLATFORMS=("${PLATFORMS[@]}" $WIN32_IA32)
        ;;
      --all)
        PLATFORMS=${ALLPLATFORMS[*]}
        break
        ;;
      -h|--help|--usage)
        echo "Usage: bash deploy.sh [platforms]"
        echo "  platforms:"
        echo "    --all : all platforms, equivalent to no argument"
        echo "    --darwin-x64 : Mac OSX 64 bits"
        echo "    --win32-x64 : Windows 64 bits"
        echo "    --win32-ia32 : Windows 32 bits"
        echo "    --linux-x64 : Linux 64 bits"
        echo "    --linux-ia32 : Linux 32 bits"
        echo ""
        echo "  --help or -h or --usage : show this help"
        exit
        ;;
      *)
        # unknown option
        echo "unknown: $key"
        exit
        ;;
    esac
    shift # past argument or value
  done
fi
#
for dep in curl unzip sed; do
  echo "checking dependency... $dep"
  test ! $(which $dep) && echo "ERROR: missing $dep" && exit 1
done

ELECTRON_VERSION=$(npm list --depth=0 |grep electron-prebuilt | cut -f2 -d@)
VERSION=$(node -e "console.log(require('./package').version)")

mkdir -p dist
cd dist
for PLATFORM in ${PLATFORMS[*]}; do
  rm -rf $PLATFORM
  echo "https://github.com/atom/electron/releases/download/v$ELECTRON_VERSION/electron-v$ELECTRON_VERSION-$PLATFORM.zip"
  test ! -f electron-v$ELECTRON_VERSION-$PLATFORM.zip && \
    curl -LO https://github.com/atom/electron/releases/download/v$ELECTRON_VERSION/electron-v$ELECTRON_VERSION-$PLATFORM.zip
  unzip -o electron-v$ELECTRON_VERSION-$PLATFORM.zip -d $PLATFORM
done

build_darwin_x64() {
  cd $DARWIN_X64
  mv Electron.app YakYak.app
  defaults write $(pwd)/YakYak.app/Contents/Info.plist CFBundleDisplayName -string "YakYak"
  defaults write $(pwd)/YakYak.app/Contents/Info.plist CFBundleExecutable -string "YakYak"
  defaults write $(pwd)/YakYak.app/Contents/Info.plist CFBundleIdentifier -string "com.github.yakyak"
  defaults write $(pwd)/YakYak.app/Contents/Info.plist CFBundleName -string "YakYak"
  defaults write $(pwd)/YakYak.app/Contents/Info.plist CFBundleVersion -string "$VERSION"
  plutil -convert xml1 $(pwd)/YakYak.app/Contents/Info.plist
  mv YakYak.app/Contents/MacOS/Electron YakYak.app/Contents/MacOS/YakYak
  cp -R ../../app YakYak.app/Contents/Resources/app
  cp ../../src/icons/icon.icns YakYak.app/Contents/Resources/electron.icns
  zip -r -y -X ../yakyak-osx.app.zip YakYak.app
  # ditto -c -k --rsrc --extattr --keepParent YakYak.app ../yakyak-osx.app.zip
  cd ..
}

build_win32_ia32 () {
  cd $WIN32_IA32
  mv electron.exe yakyak.exe
  cp -R ../../app resources/app
  cd ..
  zip -r yakyak-win32-ia32.zip win32-ia32
  # ditto -c -k --rsrc --extattr --keepParent win32-ia32 yakyak-win32-ia32.zip
}

build_win32_x64 () {
  cd $WIN32_X64
  mv electron.exe yakyak.exe
  cp -R ../../app resources/app
  cd ..
  zip -r yakyak-win32-x64.zip win32-x64
  # ditto -c -k --rsrc --extattr --keepParent win32-x64 yakyak-win32-x64.zip
}

build_linux_ia32 () {
  cd $LINUX_IA32
  mv electron yakyak
  cp -R ../../app resources/app
  cd ..
  zip -r yakyak-linux-ia32.zip linux-ia32
  # ditto -c -k --rsrc --extattr --keepParent linux-ia32 yakyak-linux-ia32.zip
}

build_linux_x64 () {
  cd $LINUX_X64
  mv electron yakyak
  cp -R ../../app resources/app
  cd ..
  zip -r yakyak-linux-x64.zip linux-x64
  # ditto -c -k --rsrc --extattr --keepParent linux-x64 yakyak-linux-x64.zip
  cd ..
}


[[ $PLATFORMS =~ $DARWIN_X64 ]] && build_darwin_x64
[[ $PLATFORMS =~ $WIN32_IA32 ]] && build_win32_ia32
[[ $PLATFORMS =~ $WIN32_X64 ]] && build_win32_x64
[[ $PLATFORMS =~ $LINUX_IA32 ]] && build_linux_ia32
[[ $PLATFORMS =~ $LINUX_X64 ]] && build_linux_x64


