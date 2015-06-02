yakyak
======

[![Build Status](https://travis-ci.org/yakyak/yakyak.svg)](https://travis-ci.org/yakyak/yakyak) [![Gitter](https://d378bf3rn661mp.cloudfront.net/gitter.svg)](https://gitter.im/yakyak/yakyak)

Desktop client for Google Hangouts

## Setup

```bash
$ npm install
$ gulp
```

## Continuous build

```
$ gulp watch
```

## Run it

```
$ electron app
```

## Structure

- `src/`: is where sources live
- `src/ui/`: holds renderer code
- `Yakyak.app/`: is where the app is built
- `Yakyak.app/Contents/Resources/app/`: specifically all is compiled to here
