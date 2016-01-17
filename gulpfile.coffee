gulp       = require 'gulp'
coffee     = require 'gulp-coffee'
less       = require 'gulp-less'
rimraf     = require 'rimraf'
path       = require 'path'
fs         = require 'fs'
gutil      = require 'gulp-util'
sourcemaps = require 'gulp-sourcemaps'
install    = require 'gulp-install'
{execSync} = require 'child_process'
concat     = require 'gulp-concat'
autoReload = require 'gulp-auto-reload'
changed    = require 'gulp-changed'
rename     = require 'gulp-rename'

outapp = './app'
outui  = outapp + '/ui'

paths =
    README:  './README.md'
    package: './package.json'
    coffee:  './src/**/*.coffee'
    html:    './src/**/*.html'
    images:  './src/**/images/*.*'
    icons:   './src/icons'
    less:    './src/**/*.less'
    css:     './src/**/*.css'
    fonts:   ['./src/**/*.eot', './src/**/*.svg',
              './src/**/*.ttf', './src/**/*.woff']

# setup package stuff (README, package.json)
gulp.task 'package', ->
    gulp.src paths.README
#        .pipe changed outapp
        .pipe gulp.dest outapp

    # install runtime deps
    gulp.src paths.package
#        .pipe changed outapp
        .pipe gulp.dest outapp
        .pipe install(production:true)


# compile coffeescript
gulp.task 'coffee', ->
    gulp.src paths.coffee
        .pipe sourcemaps.init()
        .pipe coffee()
        .on 'error', (e) ->
            console.log e.toString()
            @emit 'end'
        .pipe sourcemaps.write()
#        .pipe changed outapp
        .pipe gulp.dest outapp


# reloader will inject <script> tag
htmlInject = -> gutil.noop()

# copy .html-files
gulp.task 'html', ->
    gulp.src paths.html
        .pipe htmlInject()
        .pipe gulp.dest outapp

# copy images
gulp.task 'images', ->
    gulp.src paths.images
        .pipe gulp.dest outapp


gulp.task 'icons', ->
    nameMap =
        'icon_016.png': 'icon.png'
        'icon-unread.png': 'icon-unread.png'
        'icon_032.png': 'icon@2.png'
        'icon_048.png': 'icon@3.png'
        'icon_128.png': 'icon@8.png'
        'icon_256.png': 'icon@16.png'
        'icon_512.png': 'icon@32.png'

    Object.keys(nameMap).forEach (name) ->
        gulp.src path.join paths.icons, name
            .pipe rename nameMap[name]
            .pipe gulp.dest path.join outapp, 'icons'

# compile less
gulp.task 'less', ->
    gulp.src paths.less
        .pipe sourcemaps.init()
        .pipe less()
        .on 'error', (e) ->
            console.log e
            @emit 'end'
        .pipe concat('ui/app.css')
        .pipe sourcemaps.write()
        .pipe gulp.dest outapp


# fontello/css
gulp.task 'fontello', ->
    gulp.src [paths.css, paths.fonts...]
        .pipe gulp.dest outapp


gulp.task 'reloader', ->
    # create an auto reload server instance
    reloader = autoReload()

    # copy the client side script
    reloader.script()
        .pipe gulp.dest outui

    # inject scripts in html
    htmlInject = reloader.inject

    # watch rebuilt stuff
    gulp.watch "#{outui}/**/*", reloader.onChange


gulp.task 'clean', (cb) ->
    rimraf outapp, cb

gulp.task 'default', ['package', 'coffee', 'html', 'images', 'icons', 'less', 'fontello']

gulp.task 'watch', ['default', 'reloader', 'html'], ->
    # watch to rebuild
    sources = (v for k, v of paths)
    gulp.watch sources, ['default']
