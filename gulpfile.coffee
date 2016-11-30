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
packager   = require 'electron-packager'
zip        = require 'gulp-zip'
Q          = require 'q'
tap        = require 'gulp-tap'
Stream     = require 'stream'

outapp = './app'
outui  = outapp + '/ui'

paths =
    deploy:  './dist/'
    README:  './README.md'
    package: './package.json'
    coffee:  './src/**/*.coffee'
    html:    './src/**/*.html'
    images:  './src/**/images/*.*'
    icons:   './src/icons'
    less:    './src/ui/css/manifest.less'
    lessd:   './src/ui/css/**/*.less'
    css:     './src/**/*.css'
    fonts:   ['./src/**/*.eot', './src/**/*.svg',
              './src/**/*.ttf', './src/**/*.woff',
              './src/**/*.woff2']

outdeploy = './dist'

platformOpts = ['linux', 'darwin', 'win32']
archOpts =      ['x64','ia32']

deploy_options = {
    dir: __dirname
    asar: false
    icon: path.join __dirname, 'ui', 'icons', 'icon'
    out: path.join __dirname, 'dist'
    overwrite: true
    win32metadata: {
        CompanyName: 'Yakyak'
        ProductName: 'Yakyak'
    }
    arch:     archOpts.join ','
    platform: platformOpts.join ','
}

#
# extension to gulp to get the current task name
gulp.Gulp.prototype.__runTask = gulp.Gulp.prototype._runTask
gulp.Gulp.prototype._runTask = (task) ->
    this.currentTask = task
    this.__runTask(task)
#
# create tasks for different platforms and architectures supported
platformOpts.map (plat) ->
    # create a task per platform
    gulp.task "deploy:#{plat}", ->
        args = this.currentTask.name.replace('deploy:', '')
        deferred = Q.defer()
        archOpts.map (arch) ->
            deploy args, arch, () ->
                deferred.resolve()
        deferred.promise
    #
    #
    archOpts.map (arch) ->
        # create a task per platform/architecture
        gulp.task "deploy:#{plat}-#{arch}", ->
            deferred = Q.defer()
            args = this.currentTask.name.replace('deploy:', '').split('-')
            deploy args[0], args[1], () ->
                deferred.resolve()
            deferred.promise
#
# task to deploy all
gulp.task 'deploy', ->
    platformOpts.map (plat) ->
        archOpts.map (arch) ->
        deploy(plat, arch)

deploy = (platform, arch, fun) ->
    opts = deploy_options
    opts.platform = platform
    opts.arch = arch
    #
    # necessary to add a callback to pipe (which is used to signal end of task)
    gulpCallback = (obj) ->
        "use strict"
        stream = new Stream.Transform({objectMode: true})
        stream._transform = (file, unused, callback) ->
            obj()
            callback(null, file)
        stream
    #
    # package the app and create a zip
    packager opts, (err, appPaths) ->
        if err?
            console.log ('Error: ' + err) if err?
        else
            json = JSON.parse(fs.readFileSync('./package.json'))
            zippaths = appPaths.map (filePath) ->
                filePath + '/*'
            console.log "Compressing #{zippaths.join(', ')}"
            gulp.src zippaths
                .pipe zip "yakyak-#{platform}-#{arch}-#{json.version}.zip"
                .pipe gulp.dest outdeploy
                .pipe gulpCallback ()->
                    fun()

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
        'icon-unread@2x.png': 'icon-unread@2x.png'
        'icon-read.png': 'icon-read.png'
        'icon-read@2x.png': 'icon-read@2x.png'
        'osx-icon-unread-Template.png': 'osx-icon-unread-Template.png'
        'osx-icon-unread-Template@2x.png': 'osx-icon-unread-Template@2x.png'
        'osx-icon-read-Template.png': 'osx-icon-read-Template.png'
        'osx-icon-read-Template@2x.png': 'osx-icon-read-Template@2x.png'
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
