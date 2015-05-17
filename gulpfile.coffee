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

outbin = './Yakayak.app'
outapp = './Yakayak.app/Contents/Resources/app'

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
    .pipe gulp.dest outapp

  # install runtime deps
  gulp.src './package.json'
    .pipe gulp.dest outapp
    .pipe install(production:true)

  # compile coffeescript
  gulp.src './src/**/*.coffee'
    .pipe sourcemaps.init()
    .pipe coffee().on 'error', gutil.log
    .pipe sourcemaps.write()
    .pipe gulp.dest outapp

  # move .html-files
  gulp.src './src/**/*.html'
    .pipe gulp.dest outapp

  # compile less
  gulp.src './src/**/*.less'
    .pipe sourcemaps.init()
    .pipe less().on 'error', gutil.log
    .pipe concat('ui/app.css')
    .pipe sourcemaps.write()
    .pipe gulp.dest outapp


gulp.task 'watch', ['default'], ->
  gulp.watch './src/**/*', ['default']
