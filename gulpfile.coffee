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
filter     = require 'gulp-filter'
Q          = require 'q'
Stream     = require 'stream'
spawn      = require('child_process').spawn
# running tasks in sequence
runSequence = require('run-sequence')

#
#
# Options

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
    media:   './src/media/*.*'
    less:    './src/ui/css/manifest.less'
    lessd:   './src/ui/css/**/*.less'
    css:     './src/**/*.css'
    fonts:   ['./src/**/*.eot', './src/**/*.svg',
              './src/**/*.ttf', './src/**/*.woff',
              './src/**/*.woff2']

#
#
# Options for packaging app
#
outdeploy = path.join __dirname, 'dist'

platformOpts = ['linux', 'darwin', 'win32']
archOpts =     ['x64','ia32']

deploy_options = {
    dir: path.join __dirname, 'app'
    asar: false
    icon: path.join __dirname, 'src', 'icons', 'icon'
    out: outdeploy
    overwrite: true
    'app-bundle-id': 'com.github.yakyak'
    win32metadata: {
        CompanyName: 'Yakyak'
        ProductName: 'Yakyak'
    }
    'osx-sign': true
    arch:     archOpts.join ','
    platform: platformOpts.join ','
}

#
#
# End of options

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
gulp.task 'media', ->
    gulp.src paths.media
        .pipe gulp.dest path.join outapp, 'media'

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

    # gulp 4 requires async notification!
    new Promise (resolve, reject)->
        Object.keys(nameMap).forEach (name) ->
            gulp.src path.join paths.icons, name
                .pipe rename nameMap[name]
                .pipe gulp.dest path.join outapp, 'icons'
        resolve()

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

gulp.task 'default', ['package', 'coffee', 'html', 'images', 'media',
                      'icons', 'less', 'fontello']

gulp.task 'watch', ['default', 'reloader', 'html'], ->
    # watch to rebuild
    sources = (v for k, v of paths)
    gulp.watch sources, ['default']

#
#
#
# Deployment related tasks

#
#
buildDeployTask = (platform, arch) ->
    # create a task per platform
    taskname = "deploy:#{platform}-#{arch}"
    tasknameNoDep = "#{taskname}:nodep"
    # set internal task with _ (does not have dependencies)
    gulp.task tasknameNoDep, ()->
        deploy platform, arch
    # set task with dependencies
    gulp.task taskname, (cb) ->
      runSequence 'default', tasknameNoDep, cb
    #
    tasknameNoDep

#
# task to deploy all
allNames = []
#
# create tasks for different platforms and architectures supported
platformOpts.map (plat) ->
    names = []
    archOpts.map (arch) ->
        # create a task per platform/architecture
        taskName = buildDeployTask(plat, arch)
        names.push taskName
        allNames.push taskName
    #
    # create arch-independet task
    gulp.task "deploy:#{plat}", (cb) ->
      # add callback to arguments
      names.push cb
      runSequence 'default', names...
    #
gulp.task 'deploy', ['default'].concat allNames

zipIt = (folder, filePrefix, done) ->
    ext = 'zip'
    zipName = path.join outdeploy, "#{filePrefix}.#{ext}"
    folder = path.basename folder
    #
    args = ['-r', '-q', '-y', '-X', zipName, folder]
    opts = {
        cwd: outdeploy
        stdio: [0, 1, 'pipe']
    }
    compressIt('zip', args, opts, zipName, done)

tarIt = (folder, filePrefix, done) ->
    ext = 'tar.gz'
    zipName = path.join outdeploy, "#{filePrefix}.#{ext}"
    folder = path.basename folder
    #
    args = ['-czf', zipName, folder]
    opts = {
        cwd: outdeploy
        stdio: [0, 1, 'pipe']
    }
    compressIt('tar', args, opts, zipName, done)

compressIt = (cmd, args, opts, zipName, done) ->
    #
    # create child process
    child = spawn cmd
    , args
    , opts
    # log all errors
    child.on 'error', (err) ->
        console.log 'Error: ' + err
        process.exit(1)
    # show err
    child.on 'exit', (code) ->
        if code == 0
            console.log "Created archive (#{zipName})"
            done()
        else
            console.log "Possible problem with archive #{zipname} " +
                "-- (exit with #{code})"
            done()
            process.exit(1)

#
#
deploy = (platform, arch) ->
    deferred = Q.defer()
    opts = deploy_options
    opts.platform = platform
    opts.arch = arch
    #
    # restriction darwin won't compile ia32
    if platform == 'darwin' && arch == 'ia32'
        deferred.resolve()
        deferred.promise
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
    packOpts = opts
    if platform == 'darwin'
        packOpts.name = 'YakYak'
    packager packOpts, (err, appPaths) ->
        if err?
            console.log ('Error: ' + err) if err?
        else if appPaths?.length > 0
            json = JSON.parse(fs.readFileSync('./package.json'))
            zippath = "#{appPaths[0]}/"
            if platform == 'darwin'
                fileprefix = "yakyak-#{json.version}-osx"
            else
                fileprefix = "yakyak-#{json.version}-#{platform}-#{arch}"

            if platform == 'linux'
                tarIt zippath, fileprefix, -> deferred.resolve()
            else
                zipIt zippath, fileprefix, -> deferred.resolve()
    deferred.promise
