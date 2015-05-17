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

gulp.task 'clean', (cb) ->
  rimraf outbin, cb

copyPrebuilt = ->
  # XXX this stinks, but gulp can't deal with
  # the symlinks in the binary.
  gutil.log 'Copying prebuilt binary to', gutil.colors.magenta(outbin)
  execSync 'cp -R node_modules/electron-prebuilt/dist/Electron.app Yakayak.app'

gulp.task 'pre', ->
  copyPrebuilt() unless fs.existsSync outbin

gulp.task 'default', ['pre'], ->

  gulp.src './README.md'
    .pipe changed outapp
    .pipe gulp.dest outapp

  # install runtime deps
  gulp.src './package.json'
    .pipe changed outapp
    .pipe gulp.dest outapp
    .pipe install(production:true)

  # compile coffeescript
  gulp.src './src/**/*.coffee'
    .pipe sourcemaps.init()
    .pipe coffee().on 'error', gutil.log
    .pipe sourcemaps.write()
    .pipe changed outapp
    .pipe gulp.dest outapp

  # move .html-files
  gulp.src './src/**/*.html'
    .pipe changed outapp
    .pipe gulp.dest outapp

  # compile less
  gulp.src './src/**/*.less'
    .pipe sourcemaps.init()
    .pipe less().on 'error', gutil.log
    .pipe concat('ui/app.css')
    .pipe sourcemaps.write()
    .pipe changed outapp
    .pipe gulp.dest outapp


gulp.task 'watch', ['default'], ->

  # create an auto reload server instance
  reloader = autoReload()

  # copy the client side script
  reloader.script()
    .pipe gulp.dest outui

  # watch to rebuild
  gulp.watch './src/**/*', ['default']

  # watch rebuilt stuff
  gulp.watch "#{outui}/**/*", reloader.onChange
