yakayak
=======

Desktop client for Google Hangouts

## To run

### build

`npm` install electron and, copy a fresh `Electron.app` to
`output/Yakayak.app. brunch build to app dir. and `npm` install
runtime packages.

```bash
$ ./build.sh
```

### start two watchers

1. `coffee` runs a watcher on `src` to `app/assets`
2. `brunch` runs a watcher on `app` to `output/Yakayak.app/Contents/Resources/app`

```bash
$ npm run watch
```

### start the app

```bash
$ ./run.sh
```

## Files

```
./package.json          - builder/dev package.json
./bower.json            - "web client" side scripts
app/                    - client application code (brunch source)
app/assets/package.json - app runtime package.json
output/                 - build and output directory
output/Yakayak.app/Contents/Resources/app  - where brunch builds to
src/                    - intended server side code
```

