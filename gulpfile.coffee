gulp   = require 'gulp'
coffee = require 'gulp-coffee'
less   = require 'gulp-less'
rimraf     = require 'rimraf'
fs         = require 'fs'
gutil      = require 'gulp-util'
sourcemaps = require 'gulp-sourcemaps'
install    = require 'gulp-install'
{execSync} = require 'child_process'
concat     = require 'gulp-concat'
autoReload = require 'gulp-auto-reload'
changed    = require 'gulp-changed'

outbin = './Yakayak.app'
outapp = './Yakayak.app/Contents/Resources/app'
outui  = outapp + '/ui'

copyPrebuilt = ->
  # XXX this stinks, but gulp can't deal with
  # the symlinks in the binary.
  gutil.log 'Copying prebuilt binary to', gutil.colors.magenta(outbin)
  execSync 'cp -R node_modules/electron-prebuilt/dist/Electron.app Yakayak.app'

gulp.task 'pre', ->
  copyPrebuilt() unless fs.existsSync outbin

paths =
  README:  './README.md'
  package: './package.json'
  coffee:  './src/**/*.coffee'
  html:    './src/**/*.html'
  less:    './src/**/*.less'


# setup package stuff (README, package.json)
gulp.task 'package', ['pre'], ->
  gulp.src paths.README
    .pipe changed outapp
    .pipe gulp.dest outapp

  # install runtime deps
  gulp.src paths.package
    .pipe changed outapp
    .pipe gulp.dest outapp
    .pipe install(production:true)


# compile coffeescript
gulp.task 'coffee', ->
  gulp.src paths.coffee
    .pipe sourcemaps.init()
    .pipe coffee().on 'error', gutil.log
    .pipe sourcemaps.write()
    .pipe changed outapp
    .pipe gulp.dest outapp


# copy .html-files
gulp.task 'html', ->
  gulp.src paths.html
    .pipe changed outapp
    .pipe gulp.dest outapp


# compile less
gulp.task 'less', ->
  gulp.src paths.less
    .pipe sourcemaps.init()
    .pipe less().on 'error', gutil.log
    .pipe concat('ui/app.css')
    .pipe sourcemaps.write()
    .pipe gulp.dest outapp


gulp.task 'reloader', ->
  # create an auto reload server instance
  reloader = autoReload()

  # copy the client side script
  reloader.script()
    .pipe gulp.dest outui

  # watch rebuilt stuff
  gulp.watch "#{outui}/**/*", reloader.onChange


gulp.task 'clean', (cb) ->
  rimraf outbin, cb

gulp.task 'default', ['package', 'coffee', 'html', 'less']

gulp.task 'watch', ['reloader'], ->
  # watch to rebuild
  sources = (v for k, v of paths)
  gulp.watch sources, ['default']
