gulp   = require 'gulp'
usemin = require 'gulp-usemin'
uglify = require 'gulp-uglify'
coffee = require 'gulp-coffee'
less   = require 'gulp-less'
minifyCss  = require 'gulp-minify-css'
rimraf     = require 'rimraf'
{execSync} = require 'child_process'
fs     = require 'fs'
gutil  = require 'gulp-util'
sourcemaps = require 'gulp-sourcemaps'

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

  gulp.src

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
    .pipe less()
    .pipe sourcemaps.write()
    .pipe gulp.dest outapp


gulp.task 'watch', ['default'], ->
  gulp.watch './src/**/*', ['default']
