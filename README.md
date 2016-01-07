YakYak
======

[![Build Status](https://travis-ci.org/yakyak/yakyak.svg)](https://travis-ci.org/yakyak/yakyak) [![Gitter](https://d378bf3rn661mp.cloudfront.net/gitter.svg)](https://gitter.im/yakyak/yakyak)

Desktop client for Google Hangouts

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

What doesn't it do (yet?):

* Have a serious icon (this is being adressed)

![YakYak](https://cloud.githubusercontent.com/assets/227204/8255223/b6409032-169e-11e5-8953-488413b305b4.png)

![YakYak with thumbs](https://cloud.githubusercontent.com/assets/227204/8255540/d922d252-16a0-11e5-86b2-bfec901bbdbc.png)

## Credits

#### Main authors

* [Davide Bertola](https://github.com/davibe)
* [Martin Algesten](https://github.com/algesten)

#### Contributors

* [David Banham](https://github.com/davidbanham)
* [Max Kueng](https://github.com/maxkueng)

## Developing

This is an open source project. Please help us!

It is written in coffeescript (nodejs) based on
[hangupsjs](https://github.com/algesten/hangupsjs) using
[trifl](http://algesten.github.io/trifl/) on top of
[electron (atom shell)](https://github.com/atom/electron).

### Setup

```bash
$ sudo npm install -g gulp
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

You might want to put the electron binary on your $PATH or symlink it. npm puts
it at `node_modules/electron-prebuilt/dist/electron`.

### Structure

- `src/`: is where sources live
- `src/ui/`: holds renderer code (client side)
- `YakYak.app/`: is where the app is built
- `YakYak.app/Contents/Resources/app/`: specifically all is compiled to here
