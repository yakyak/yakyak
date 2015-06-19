yakyak
======

[![Build Status](https://travis-ci.org/yakyak/yakyak.svg)](https://travis-ci.org/yakyak/yakyak) [![Gitter](https://d378bf3rn661mp.cloudfront.net/gitter.svg)](https://gitter.im/yakyak/yakyak)

Desktop client for Google Hangouts

(This app is in no way associated with or endorsed by Google)

## Install it

This a beta. We love bug reports!

Mac OS X - download the [disk image here](https://github.com/yakyak/yakyak/releases/download/v0.0.1/Yakyak.dmg.zip).

What does it do:

* Send/receive chat messages
* Create/change conversations (rename, add people)
* Leave/delete conversation
* Notifications
* Toggle notifications on/off
* Drag-drop or copy-paste images
* Hangupsbot sync room aware (no bot name, proper user pics)
* Show inline images
* Send presence/focus/typing to behave like a proper client

What doesn't it do (yet?):

* History scrollback
* Proper video/audio integration (plan to open in chrome)
* Focus/typing indications (mainly a design issue. keep it clean)
* Have a serious icon
* Windows binary (though that should be easy)

![yakyak](https://cloud.githubusercontent.com/assets/227204/8255223/b6409032-169e-11e5-8953-488413b305b4.png)

## Credits

#### Main authors

* [Davide Bertola](https://github.com/davibe)
* [Martin Algesten](https://github.com/algesten)

#### Contributors

* Someone soon... (we hope)

## Developing

This is an open source project. Please help us!

It is written in coffeescript (nodejs) based on
[hangupsjs](https://github.com/algesten/hangupsjs) using
[trifl](http://algesten.github.io/trifl/) on top of
[electron (atom shell)](https://github.com/atom/electron).

### Setup

```bash
$ npm install
$ gulp
```

### Continuous build

```
$ gulp watch
```

### Run it

```
$ electron app
```

### Structure

- `src/`: is where sources live
- `src/ui/`: holds renderer code (client side)
- `Yakyak.app/`: is where the app is built
- `Yakyak.app/Contents/Resources/app/`: specifically all is compiled to here
