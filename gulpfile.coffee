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
flatpak    = require 'electron-installer-flatpak'
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
    locales: './src/locales/*.json'
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

json = JSON.parse(fs.readFileSync('./package.json'))

deploy_options = {
    dir: path.join __dirname, 'app'
    asar: false
    icon: path.join __dirname, 'src', 'icons', 'icon'
    out: outdeploy
    overwrite: true
    appBundleId: 'com.github.yakyak'
    win32metadata: {
        CompanyName: 'Yakyak'
        ProductName: 'Yakyak'
        OriginalFilename: 'Yakyak.exe'
        FileDescription: 'Yakyak'
        InternalName: 'Yakyak.exe'
        FileVersion: "#{json.version}"
        ProductVersion: "#{json.version}"
    }
    osxSign: true
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
gulp.task 'locales', ->
    gulp.src paths.locales
        .pipe gulp.dest path.join outapp, 'locales'

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
        # Icons
        'icon_016.png': 'icon.png'
        'icon_032.png': 'icon@2.png'
        'icon_048.png': 'icon@3.png'
        'icon_128.png': 'icon@8.png'
        'icon_256.png': 'icon@16.png'
        'icon_512.png': 'icon@32.png'
        # Unread icon in tray (linux/windows)
        'icon-unread_016.png': 'icon-unread.png'
        'icon-unread_032.png': 'icon-unread@2x.png'
        'icon-unread_128.png': 'icon-unread@8x.png'
        # Read icon in tray (linux/windows)
        'icon-read_016.png': 'icon-read.png'
        'icon-read_032.png': 'icon-read@2x.png'
        'icon-read_128.png': 'icon-read@8x.png'
        # Unread icon in tray (Mac OS X)
        'osx-icon-unread-Template_016.png': 'osx-icon-unread-Template.png'
        'osx-icon-unread-Template_032.png': 'osx-icon-unread-Template@2x.png'
        # Read icon in tray (Mac OS X)
        'osx-icon-read-Template_016.png': 'osx-icon-read-Template.png'
        'osx-icon-read-Template_032.png': 'osx-icon-read-Template@2x.png'

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
                      'locales', 'icons', 'less', 'fontello']

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
names = {linux: [], win32: [], darwin: []}
#

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
            console.log "Possible problem with archive #{zipName} " +
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
            if process.env.NO_ZIP
                return deferred.resolve()
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

archOpts.forEach (arch) ->
    ['deb', 'rpm'].forEach (target) ->
        gulp.task 'deploy:linux-' + arch + ':' + target, (done) ->
            if arch is 'ia32'
                archName = 'i386'
            else if target is 'deb'
                archName = 'amd64'
            else
                archName = 'x86_64'

            packageName = json.name + '-VERSION-linux-ARCH.' + target
            iconArgs = [16, 32, 48, 128, 256, 512].map (size) ->
                if size < 100
                    src = "0#{size}"
                else
                    src = size
                "./src/icons/icon_#{src}.png=/usr/share/icons/hicolor/#{size}x#{size}/apps/#{json.name}.png"
            fpmArgs = [
                '-s', 'dir'
                '--loglevel', 'debug'
                '-t', target
                '--architecture', archName
                '--rpm-os', 'linux'
                '--name', json.name
                '--force' # Overwrite existing files
                '--license', json.license
                '--description', json.description
                '--url', json.homepage
                '--maintainer', json.author
                '--vendor', json.authorName
                '--version', json.version
                '--package', "./dist/#{packageName}"
                '--after-install', './resources/linux/after-install.sh'
                '--after-remove', './resources/linux/after-remove.sh'
                "./dist/#{json.name}-linux-#{arch}/.=/opt/#{json.name}"
                "./resources/linux/app.desktop=/usr/share/applications/#{json.name}.desktop"
            ].concat iconArgs

            child = spawn 'fpm', fpmArgs
            # log all errors
            child.on 'error', (err) ->
                console.log 'Error: ' + err, fpmArgs
                process.exit(1)
            # show err
            child.on 'exit', (code) ->
                if code == 0
                    console.log "Created #{target} (#{packageName})"
                    done()
                else
                    console.log "Possible problem with #{target} #{packageName} " +
                        "-- (exit with #{code})"
                    done()
                    process.exit(1)
        names['linux'].push 'deploy:linux-' + arch + ':' + target
        allNames.push('deploy:linux-' + arch + ':' + target)

    gulp.task 'deploy:linux-' + arch + ':flatpak', (done) ->
        flatpakOptions =
            id: 'com.github.yakyak.YakYak'
            arch: arch
            runtimeVersion: "1.6"
            src: 'dist/yakyak-linux-' + arch
            dest: 'dist/'
            genericName: 'Internet Messenger'
            productName: 'YakYak'
            icon:
                '16x16': 'src/icons/icon_016.png'
                '32x32': 'src/icons/icon_032.png'
                '48x48': 'src/icons/icon_048.png'
                '128x128': 'src/icons/icon_128.png'
                '256x256': 'src/icons/icon_256.png'
                '512x512': 'src/icons/icon_512.png'
            categories: ['Network', 'InstantMessaging']
        flatpak flatpakOptions, (err) ->
            if err
                console.error err.stack
                done()
                process.exit 1
            else
                console.log "Created flatpak (#{json.name}_#{json.version}_#{arch}.flatpak)"
                done()
    names['linux'].push 'deploy:linux-' + arch + ':flatpak'
    allNames.push('deploy:linux-' + arch + ':flatpak')

# create tasks for different platforms and architectures supported
platformOpts.map (plat) ->
    archOpts.map (arch) ->
        # create a task per platform/architecture
        taskName = buildDeployTask(plat, arch)
        names[plat].push taskName
        allNames.push taskName
    #
    # create arch-independet task
    gulp.task "deploy:#{plat}", (cb) ->
      # add callback to arguments
      this_names = names[plat]
      this_names.push cb
      runSequence 'default', names[plat]...
    #

gulp.task 'deploy', (cb)->
    allNames.push cb
    runSequence 'default', allNames...
