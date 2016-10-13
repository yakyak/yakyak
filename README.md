YakYak
======

[![Build Status](https://travis-ci.org/yakyak/yakyak.svg)](https://travis-ci.org/yakyak/yakyak) [![Gitter](https://d378bf3rn661mp.cloudfront.net/gitter.svg)](https://gitter.im/yakyak/yakyak)

Desktop client for Google Hangouts

![sshot](https://cloud.githubusercontent.com/assets/123929/16032313/cdba46c2-3204-11e6-912f-a72fef60563a.png)

(This app is in no way associated with or endorsed by Google)

## Install it

We provide [prebuilt binaries](https://github.com/yakyak/yakyak/releases) for Mac OS X, Linux 32 / 64 and Windows 32 / 64.

This is the [latest release](https://github.com/yakyak/yakyak/releases/latest).
We love [bug reports](https://github.com/yakyak/yakyak/issues)!

What does it do:

* Send/receive chat messages
* Create/change conversations (rename, add people)
* Leave/delete conversation
* Notifications
* Toggle notifications on/off
* Drag-drop, copy-paste or attach-button for image upload.
* Hangupsbot sync room aware (no bot name, proper user pics)
* Show inline images
* Send presence/focus/typing/activeclient to behave like a proper client
* History scrollback
* Video/audio integration (open in chrome)
* Focus/typing indications (mainly a design issue. keep it clean)
* Offer alternative color schemes

![sshot1](https://cloud.githubusercontent.com/assets/123929/16032393/991d63f8-3205-11e6-98bf-31f1b57cdc96.png)

![sshot2](https://cloud.githubusercontent.com/assets/123929/16032394/9e2ac08e-3205-11e6-81cc-fd4cb37441b5.png)


## Credits

#### Main authors

* [Davide Bertola](https://github.com/davibe)
* [Martin Algesten](https://github.com/algesten)

#### Contributors

* [David Banham](https://github.com/davidbanham)
* [Max Kueng](https://github.com/maxkueng)
* [Arnaud Riu](https://github.com/arnriu)
* [Austin Guevara](https://github.com/austin-guevara)

## Developing

This is an open source project. Please help us!

It is written in coffeescript (nodejs) based on
[hangupsjs](https://github.com/algesten/hangupsjs) using
[trifl](http://algesten.github.io/trifl/) on top of
[electron (atom shell)](https://github.com/atom/electron).

### Setup

```bash
$ npm install
$ npm run gulp
```

### Continuous build

```
$ npm run gulp watch
```

### Run it

```
$ npm run electron app
```

### Build Binaries for Deployment

```
$ npm run deploy
```

### Structure

- `src/`: is where sources live
- `src/ui/`: holds renderer code (client side)
- `dist/`: everything is compiled to this directory
