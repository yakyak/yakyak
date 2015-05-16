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

### start a brunch watcher (to continuously build during dev)

```bash
$ brunch w
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

