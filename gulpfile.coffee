gulp       = require 'gulp'
coffee     = require 'gulp-coffee'
less       = require 'gulp-less'
rimraf     = require 'rimraf'
path       = require 'path'
fs         = require 'fs'
sourcemaps = require 'gulp-sourcemaps'
reinstall    = require 'gulp-reinstall'
{execSync} = require 'child_process'
concat     = require 'gulp-concat'
liveReload = require 'gulp-livereload'
changed    = require 'gulp-changed'
rename     = require 'gulp-rename'
packager   = require 'electron-packager'
flatpak    = try require 'electron-installer-flatpak'
debian     = try require 'electron-installer-debian'
filter     = require 'gulp-filter'
Q          = require 'q'
Stream     = require 'stream'
spawn      = require('child_process').spawn

#
#
# Options

outapp = './app'
outui  = outapp + '/ui'

paths =
    snyk:    './.snyk'
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
archOpts =     ['x64','ia32','arm64']

json = JSON.parse(fs.readFileSync('./package.json'))

deploy_options = {
    dir: path.join __dirname, 'app'
    asar:
        unpackDir: "{node_modules/node-notifier/vendor/**,icons}"
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
        .pipe reinstall()
        #.pipe reinstall({ production: true }) # electron-packager doesn't like this


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

# copy .html-files
gulp.task 'html', ->
    gulp.src paths.html
        .pipe gulp.dest outapp
        .pipe liveReload()

# copy images
gulp.task 'locales', ->
    gulp.src paths.locales
        .pipe gulp.dest path.join outapp, 'locales'

# copy images
gulp.task 'media', ->
    gulp.src paths.media
        .pipe gulp.dest path.join outapp, 'media'


gulp.task 'snyk', ->
    gulp.src paths.snyk
        .pipe gulp.dest path.join outapp
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
        'icon-unread_020.png': 'icon-unread@20.png'
        'icon-unread_128.png': 'icon-unread@8x.png'
        # Read icon in tray (linux/windows - colorblind)
        'icon-read_016_blue.png': 'icon-read_blue.png'
        'icon-read_032_blue.png': 'icon-read@2x_blue.png'
        'icon-read_020_blue.png': 'icon-read@20_blue.png'
        'icon-read_128_blue.png': 'icon-read@8x_blue.png'
        # Read icon in tray (linux/windows)
        'icon-read_016.png': 'icon-read.png'
        'icon-read_032.png': 'icon-read@2x.png'
        'icon-read_020.png': 'icon-read@20.png'
        'icon-read_128.png': 'icon-read@8x.png'
        # Unread icon in tray (Mac OS X)
        'osx-icon-unread-Template_016.png': 'osx-icon-unread-Template.png'
        'osx-icon-unread-Template_032.png': 'osx-icon-unread-Template@2x.png'
        # Read icon in tray (Mac OS X)
        'osx-icon-read-Template_016.png': 'osx-icon-read-Template.png'
        'osx-icon-read-Template_032.png': 'osx-icon-read-Template@2x.png'

    # gulp 4 requires async notification!
    new Promise (resolve, reject) ->
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
    liveReload.listen()

    # watch rebuilt stuff
    gulp.watch "#{outui}/**/*", gulp.series('html')


gulp.task 'clean', (cb) ->
    rimraf outapp, cb

gulp.task 'default',
          gulp.parallel 'package', 'coffee', 'html', 'images',
                        'media', 'locales', 'icons', 'less', 'fontello'

gulp.task 'watch', ->
    gulp.series 'default', 'reloader', 'html'
    # watch to rebuild
    sources = (v for k, v of paths)
    gulp.watch sources, gulp.series('default')

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
    gulp.task tasknameNoDep, (cb)->
        deploy platform, arch, cb
    # set task with dependencies
    gulp.task taskname, gulp.series('default', tasknameNoDep)
    #
    tasknameNoDep

#
# task to deploy all
allNames = []
names = {linux: [], win32: [], darwin: []}
#

zipIt = (folder, filePrefix, done) ->
    # use zip
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
    # use GNU tar to make gzipped tar archive
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

zipItWin = (folder, filePrefix, done) ->
    # use built-in tar.exe to make zip archive
    ext = 'zip'
    zipName = path.join outdeploy, "#{filePrefix}.#{ext}"
    folder = path.basename folder
    #
    args = ['-cf', zipName, folder]
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
deploy = (platform, arch, cb) ->
    deferred = Q.defer()
    opts = deploy_options
    opts.platform = platform
    opts.arch = arch
    #
    # restriction darwin won't compile ia32
    if platform is 'darwin' and arch is 'ia32'
        cb()
        deferred.resolve()
        return deferred.promise

    #
    # package the app and create a zip
    packOpts = opts
    if platform == 'darwin'
        packOpts.name = 'YakYak'
    #
    console.log('packOpts', packOpts)
    packager(packOpts)
        .catch (error) ->
            console.error(error)
        .then (appPaths) ->
            if appPaths?.length > 0
                if process.env.NO_ZIP
                    cb()
                    return deferred.resolve()
                zippath = "#{appPaths[0]}/"
                if platform == 'darwin'
                    fileprefix = "yakyak-#{json.version}-osx-#{arch}"
                else
                    fileprefix = "yakyak-#{json.version}-#{platform}-#{arch}"

                if platform == 'linux'
                    tarIt zippath, fileprefix, ->
                      cb()
                      deferred.resolve()
                else if platform == 'win32' && process.platform == 'win32'
                    zipItWin zippath, fileprefix, ->
                      cb()
                      deferred.resolve()
                else
                    zipIt zippath, fileprefix, ->
                      cb()
                      deferred.resolve()
    deferred.promise

# create tasks for different platforms and architectures supported
platformOpts.map (plat) ->
    archOpts.map (arch) ->
        # create a task per platform/architecture
        taskName = buildDeployTask(plat, arch)
        names[plat].push taskName
        allNames.push taskName
    #
    # create arch-independet task
    gulp.task "deploy:#{plat}", gulp.series 'default', names[plat]...
    #

archOpts.forEach (arch) ->
    ['rpm', 'pacman'].forEach (target) ->
        gulp.task "deploy:linux-#{arch}:#{target}:nodep", (done) ->

            archNameSuffix = archName
            if arch is 'ia32'
                archName = 'i386'
                archNameSuffix = 'ia32'
            else if target is 'deb'
                archName = 'amd64'
                archNameSuffix = 'amd64'
            else if arch is 'x64'
                archName = 'x86_64'
                archNameSuffix = 'x64'
            else
                archName = arch
                archNameSuffix = arch

            if target == 'pacman'
                suffix = 'tar.gz'
            else
                suffix = target

            packageName = json.name + '-' + json.version + '-linux-' + archNameSuffix +
                (if target is 'pacman' then '-pacman.' else '.') + suffix

            iconArgs = [16, 32, 48, 128, 256, 512].map (size) ->
                if size < 100
                    src = "0#{size}"
                else
                    src = size
                "./src/icons/icon_#{src}.png=/usr/share/icons/hicolor/#{size}x#{size}/apps/#{json.name}.png"
            fpmArgs = [
                '-s', 'dir'
                '--log', 'info'
                '-t', target
                '--architecture', archName
                '--rpm-os', 'linux'
                '--name', json.name
                '--force' # Overwrite existing files
                '--description', "\"#{json.description}\""
                '--license', "\"#{json.license}\""
                '--url', json.homepage
                '--maintainer', "\"#{json.author}\""
                '--vendor', "\"#{json.author}\""
                '--version', json.version
                '--package', "./dist/#{packageName}"
                '--after-install', './resources/linux/after-install.sh'
                '--after-remove', './resources/linux/after-remove.sh'
                '--pacman-compression', 'gz'
                "./dist/#{json.name}-linux-#{arch}/.=/opt/#{json.name}"
                "./resources/linux/app.desktop=/usr/share/applications/#{json.name}.desktop"
            ].concat iconArgs
            child = spawn 'fpm', fpmArgs
            child.stdout.on 'data', (data) ->
              # do nothing
              console.log("fpm: #{data}")
              done()
              return true
            # log all errors
            child.on 'error', (err) ->
                console.log 'Error: ' + err, fpmArgs
                done()
                process.exit(1)
            # show err
            child.on 'exit', (code) ->
                if code == 0
                    console.log "Created #{target} (#{packageName})"
                    done()
                else
                    console.log "Possible problem with #{target} " +
                        "(exit with code #{code})"
                    console.log 'fpm arguments: ' + fpmArgs.join(' ')
                    process.exit(1)
            return child
        #names['linux'].push 'deploy:linux-' + arch + ':' + target
        #allNames.push('deploy:linux-' + arch + ':' + target)

        gulp.task "deploy:linux-#{arch}:#{target}",
            gulp.series("deploy:linux-#{arch}", "deploy:linux-#{arch}:#{target}:nodep")

    gulp.task "deploy:linux-#{arch}:deb:nodep", (done) ->

        options = {
            src: "dist/#{json.name}-linux-#{arch}"
            dest: 'dist/'
            name: 'YakYak'
            genericName: 'IM Client'
            productName: 'YakYak'
            version: json.version
            bin: 'yakyak'
            desktopTemplate: 'resources/desktop.ejs'
            icon:
              '16x16': 'src/icons/icon_016.png'
              '32x32': 'src/icons/icon_032.png'
              '48x48': 'src/icons/icon_048.png'
              '128x128': 'src/icons/icon_128.png',
              '256x256': 'src/icons/icon_256.png',
              '512x512': 'src/icons/icon_512.png',
              'scalable': 'src/icons/yakyak-logo.svg',
            categories: [
              'GNOME'
              'GTK'
              'Network'
              'InstantMessaging'
            ]
        }

        if arch is 'ia32'
            options.arch = 'i386'
        else if arch is 'x64'
            options.arch = 'amd64'
        else
            options.arch = arch

        options.rename = (dest, src) -> path.join(dest, "#{json.name}-#{json.version}-linux-#{options.arch}.deb")
        debian options

    gulp.task "deploy:linux-#{arch}:deb",
        gulp.series("deploy:linux-#{arch}", "deploy:linux-#{arch}:deb:nodep")

    gulp.task "deploy:linux-#{arch}:flatpak:nodep", (done) ->
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
            finishArgs: ['-v']
        flatpak flatpakOptions, (err) ->
            if err
                console.error err.stack
                done()
                process.exit 1
            else
                console.log "Created flatpak (#{json.name}_#{json.version}_#{arch}.flatpak)"
                done()
    gulp.task "deploy:linux-#{arch}:flatpak",
        gulp.series("deploy:linux-#{arch}", "deploy:linux-#{arch}:flatpak:nodep")
    #names['linux'].push 'deploy:linux-' + arch + ':flatpak'
    #allNames.push('deploy:linux-' + arch + ':flatpak')

gulp.task 'deploy', gulp.series 'default', allNames...
