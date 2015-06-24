yakyak
======

[![Build Status](https://travis-ci.org/yakyak/yakyak.svg)](https://travis-ci.org/yakyak/yakyak) [![Gitter](https://d378bf3rn661mp.cloudfront.net/gitter.svg)](https://gitter.im/yakyak/yakyak)

Desktop client for Google Hangouts

(This app is in no way associated with or endorsed by Google)

## Install it

This the second beta. We love [bug reports](https://github.com/yakyak/yakyak/issues)!

Pre-built binaries:

* [Mac OS X](https://github.com/yakyak/yakyak/releases/download/v0.2.0/yakyak-osx.app.zip)
* [Linux 32](https://github.com/yakyak/yakyak/releases/download/v0.2.0/yakyak-linux-ia32.zip)
* [Linux 64](https://github.com/yakyak/yakyak/releases/download/v0.2.0/yakyak-linux-x64.zip)
* [Windows 32](https://github.com/yakyak/yakyak/releases/download/v0.2.0/yakyak-win32-ia32.zip)
* [Windows 64](https://github.com/yakyak/yakyak/releases/download/v0.2.0/yakyak-win32-x64.zip)

What does it do:

* Send/receive chat messages
* Create/change conversations (rename, add people)
* Leave/delete conversation
* Notifications
* Toggle notifications on/off
* Drag-drop or copy-paste images
* Hangupsbot sync room aware (no bot name, proper user pics)
* Show inline images
* Send presence/focus/typing/activeclient to behave like a proper client
* History scrollback
* Video/audio integration (open in chrome)
* Focus/typing indications (mainly a design issue. keep it clean)

What doesn't it do (yet?):

* Have a serious icon

![yakyak](https://cloud.githubusercontent.com/assets/227204/8255223/b6409032-169e-11e5-8953-488413b305b4.png)

![yakyak with thumbs](https://cloud.githubusercontent.com/assets/227204/8255540/d922d252-16a0-11e5-86b2-bfec901bbdbc.png)

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
