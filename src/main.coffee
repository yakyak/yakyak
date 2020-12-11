Client    = require 'hangupsjs'
Q         = require 'q'
login     = require './login'
ipc       = require('electron').ipcMain
fs        = require 'fs'
path      = require 'path'
tmp       = require 'tmp'
session   = require('electron').session
log       = require('bog');

[drive, path_parts...] = path.normalize(__dirname).split(path.sep)
global.YAKYAK_ROOT_DIR = [drive, path_parts.map(encodeURIComponent)...].join('/')

# test if flag debug is preset (other flags can be used via package args
#  but requres node v6)
debug = process.argv.includes '--debug'

tmp.setGracefulCleanup()

app = require('electron').app

console.log('Starting Yakyak v' + app.getVersion() + '...')
console.log('  using hangupsjs v' + Client.VERSION) if Client.VERSION
console.log('--------')
app.disableHardwareAcceleration() # was using a lot of resources needlessly
app.commandLine.appendSwitch('autoplay-policy', 'no-user-gesture-required')

BrowserWindow = require('electron').BrowserWindow

# Moving out of UI into main process
{ Menu, Tray, nativeImage } = require('electron')
tray = null # set global tray

# Path for configuration
userData = path.normalize(app.getPath('userData'))

# makedir if it doesn't exist
fs.mkdirSync(userData) if not fs.existsSync userData

# some default paths to store tokens needed for hangupsjs to reconnect
paths =
    rtokenpath: path.join(userData, 'refreshtoken.txt')
    cookiespath: path.join(userData, 'cookies.json')
    chromecookie: path.join(userData, 'Cookies')
    configpath: path.join(userData, 'config.json')

client = new Client(
    rtokenpath: paths.rtokenpath
    cookiespath: paths.cookiespath
)

plug = (rs, rj) -> (err, val) -> if err then rj(err) else rs(val)

logout = ->
    log.info 'Logging out...'
    promise = client.logout()
    promise.then (res) ->
        argv = process.argv
        spawn = require('child_process').spawn
        # remove electron cookies
        mainWindow?.webContents?.session?.clearStorageData([], (data) -> console.log(data))
        spawn argv.shift(), argv,
            cwd: process.cwd
            env: process.env
            detached: true
            stdio: 'inherit'
        quit()
    return promise # like it matters

seqreq = require './seqreq'

mainWindow = null

# Only allow a single active instance
gotTheLock = app.requestSingleInstanceLock()

if !gotTheLock
    app.quit()
    return

# If someone tries to run a second instance, we should focus our window.
app.on 'second-instance', (event, commandLine, workingDirectory) ->
    if mainWindow
        mainWindow.restore() if mainWindow.isMinimized()
        mainWindow.focus()

global.i18nOpts = { opts: null, locale: null }

# No more minimizing to tray, just close it
global.forceClose = false
quit = ->
    global.forceClose = true
    # force all windows to close
    mainWindow.destroy() if mainWindow?
    console.log('--------\nGoodbye')
    app.quit()
    return

app.on 'before-quit', ->
    global.forceClose = true
    global.i18nOpts = null
    return

# For OSX show window main window if we've hidden it.
# https://github.com/electron/electron/blob/master/docs/api/app.md#event-activate-os-x
app.on 'activate', ->
    mainWindow.show()

# Load the default html for the window
#  if user sees this html then it's an error and it tells how to report it
loadAppWindow = ->
    mainWindow.loadURL 'file://' + YAKYAK_ROOT_DIR + '/ui/index.html'
    # Only show window when it has some content
    mainWindow.once 'ready-to-show', () ->
        mainWindow.webContents.send 'ready-to-show'

# helper wait promise
wait = (t) -> Q.Promise (rs) -> setTimeout rs, t

#    ______ _           _
#   |  ____| |         | |                       /\
#   | |__  | | ___  ___| |_ _ __ ___  _ __      /  \   _ __  _ __
#   |  __| | |/ _ \/ __| __| '__/ _ \| '_ \    / /\ \ | '_ \| '_ \
#   | |____| |  __/ (__| |_| | | (_) | | | |  / ____ \| |_) | |_) |
#   |______|_|\___|\___|\__|_|  \___/|_| |_| /_/    \_\ .__/| .__/
#                                                     | |   | |
#                                                     |_|   |_|
app.on 'ready', ->
    proxycheck = ->
        todo = [
           {url:'http://plus.google.com',  env:'HTTP_PROXY'}
           {url:'https://plus.google.com', env:'HTTPS_PROXY'}
        ]
        Q.all todo.map (t) -> Q.Promise (rs) ->
            console.log "resolving proxy #{t.url}"
            session.defaultSession.resolveProxy(t.url).then (proxyURL) ->
                console.log "resolved proxy #{proxyURL}"
                # Format of proxyURL is either "DIRECT" or "PROXY 127.0.0.1:8888"
                [_, purl] = proxyURL.split ' '
                process.env[t.env] ?= if purl then "http://#{purl}" else ""
                rs()

    icon_name = if process.platform is 'win32' then 'icon@2.png' else 'icon@32.png'

    windowOpts = {
        width: 730
        height: 590
        "min-width": 620
        "min-height": 420
        icon: path.join __dirname, 'icons', icon_name
        show: false
        spellcheck: true
        autohideMenuBar: true
        webPreferences: {
            enableRemoteModule: true
            nodeIntegration: true
            contextIsolation: false
            # preload: path.join(app.getAppPath(), 'ui', 'app.js')
        }
        # autoHideMenuBar : true unless process.platform is 'darwin'
    }

    if process.platform is 'darwin'
        windowOpts.titleBarStyle = 'hiddenInset'

    if process.platform is 'win32'
        windowOpts.frame = false

    # Create the browser window.
    mainWindow = new BrowserWindow windowOpts

    # Launch fullscreen with DevTools open, usage: npm run debug
    if debug
        mainWindow.webContents.openDevTools()
        mainWindow.maximize()
        mainWindow.show()
        # this will also show more debugging from hangupsjs client
        log.level 'debug'
        client.loglevel 'debug'
        # devtron in not maintained
        #try
        #    require('devtron').install()
        #catch
        #    # do nothing

    # and load the index.html of the app. this may however be yanked
    # away if we must do auth.
    loadAppWindow()

    #
    #
    # Handle uncaught exceptions from the main process
    process.on 'uncaughtException', (msg) ->
        ipcsend 'expcetioninmain', msg
        #
        console.log "Error on main process:\n#{msg}\n" +
            "--- End of error message. More details:\n", msg

    #
    #
    # Handle crashes on the main window and show in console
    mainWindow.webContents.on 'crashed', (msg) ->
        console.log 'Crash event on main window!', msg
        ipc.send 'expcetioninmain', {
            msg: 'Detected a crash event on the main window.'
            event: msg
        }

    # short hand
    ipcsend = (as...) ->  mainWindow.webContents.send as...

    # callback for credentials
    creds = ->
        console.log "asking for login credentials"
        loginWindow = new BrowserWindow {
            width: 730
            height: 590
            "min-width": 620
            "min-height": 420
            icon: path.join __dirname, 'icons', 'icon.png'
            show: true
            webPreferences: {
                nodeIntegration: false
            }
        }
        loginWindow.webContents.openDevTools() if debug
        loginWindow.on 'closed', quit

        global.windowHideWhileCred = true
        mainWindow.hide()
        loginWindow.focus()
        # reinstate app window when login finishes
        prom = login(loginWindow)
        .then (rs) ->
            global.forceClose = true
            loginWindow.removeAllListeners 'closed'
            loginWindow.close()
            mainWindow.show()
            rs
        auth: -> prom

    # sends the init structures to the client
    sendInit = ->
        # we have no init data before the client has connected first
        # time.
        return false unless client?.init?.self_entity
        ipcsend 'init', init: client.init
        return true

    # keeps trying to connec the hangupsjs and communicates those
    # attempts to the client.
    reconnect = ->
        console.log 'reconnecting', reconnectCount
        proxycheck().then ->
            client.connect(creds)
            .then ->
                console.log 'connected', reconnectCount
                # on first connect, send init, after that only resync
                if reconnectCount == 0
                    log.debug 'Sending init...'
                    sendInit()
                else
                    log.debug 'SyncRecent...'
                    syncrecent()
                reconnectCount++
            .catch (e) -> console.log 'error connecting', e

    # counter for reconnects
    reconnectCount = 0

    # whether to connect is dictated by the client.
    ipc.on 'hangupsConnect', ->
        console.log 'hangupsjs:: connecting'
        reconnect()

    ipc.on 'hangupsDisconnect', ->
        console.log 'hangupsjs:: disconnect'
        reconnectCount = 0
        client.disconnect()

    # client deals with window sizing
    mainWindow.on 'resize', (ev) -> ipcsend 'resize', mainWindow.getSize()
    mainWindow.on 'move',  (ev) -> ipcsend 'move', mainWindow.getPosition()

    # whenever it fails, we try again
    client.on 'connect_failed', (e) ->
        console.log 'connect_failed', e
        wait(3000).then -> reconnect()

    #    _      _     _                     _____ _____   _____
    #   | |    (_)   | |                   |_   _|  __ \ / ____|
    #   | |     _ ___| |_ ___ _ __           | | | |__) | |
    #   | |    | / __| __/ _ \ '_ \          | | |  ___/| |
    #   | |____| \__ \ ||  __/ | | |_ _ _   _| |_| |    | |____
    #   |______|_|___/\__\___|_| |_(_|_|_) |_____|_|     \_____|
    #
    #
    # Listen on events from main window

    # when client requests (re-)init since the first init
    # object is sent as soon as possible on startup
    ipc.on 'reqinit', -> syncrecent() if sendInit()

    ipc.on 'togglefullscreen', ->
        mainWindow.setFullScreen not mainWindow.isFullScreen()

    # bye bye
    ipc.on 'logout', logout

    ipc.on 'quit', quit

    ipc.on 'errorInWindow', (ev, error, winName = 'YakYak') ->
        mainWindow.show() unless global.isReadyToShow
        ipcsend 'expcetioninmain', error
        console.log "Error on #{winName} window:\n", error, "\n--- End of error message in #{winName} window."


    # sendchatmessage, executed sequentially and
    # retried if not sent successfully
    messageQueue = Q()
    ipc.on 'sendchatmessage', (ev, msg) ->
        {conv_id, segs, client_generated_id, image_id, otr, message_action_type, delivery_medium} = msg
        sendForSure = -> Q.promise (resolve, reject, notify) ->
            attempt = ->
                # console.log 'sendchatmessage', client_generated_id
                if not delivery_medium?
                    delivery_medium = null
                client.sendchatmessage(conv_id, segs, image_id, otr, client_generated_id, delivery_medium, message_action_type).then (r) ->
                      # console.log 'sendchatmessage:result', r?.created_event?.self_event_state?.client_generated_id
                    ipcsend 'sendchatmessage:result', r
                    resolve()
            attempt()
        messageQueue = messageQueue.then ->
            sendForSure()

    # get locale for translations
    ipc.on 'seti18n', (ev, opts, language)->
        if opts?
            global.i18nOpts.opts = opts
        if language?
            global.i18nOpts.locale = language

    ipc.on 'appfocus', ->
        app.focus()
        if mainWindow.isVisible()
            mainWindow.focus()
        else
            mainWindow.show()

    ipc.handle 'tray-destroy', (ev) ->
        if tray
            tray.destroy()
            tray = null if tray.isDestroyed()

    ipc.handle 'tray', (ev, menu, iconpath, toolTip) ->
        if tray # create tray if it doesn't exist
          tray.setImage iconpath unless tray.currentImage == iconpath
        else
          tray = new Tray iconpath

        tray.currentImage = iconpath

        tray.setToolTip toolTip
        tray.on 'click', (ev) -> ipcsend 'menuaction', 'togglewindow'

        if menu
            # build functions that cannot be sent via ipc
            contextMenu = menu.map (el) ->
                el.click = (r)->
                    ipcsend 'menuaction', el.click_action
                # delete el.click_action
                el
            tray.setContextMenu Menu.buildFromTemplate contextMenu

    #
    #
    # Methods below use seqreq that returns a promise and allows for retry
    #

    # sendchatmessage, executed sequentially and
    # retried if not sent successfully
    ipc.on 'querypresence', seqreq (ev, id) ->
        client.querypresence(id).then (r) ->
            ipcsend 'querypresence:result', r.presenceResult[0]
        , false, -> 1

    ipc.on 'initpresence', (ev, l) ->
        for p, i in l when p != null
            client.querypresence(p.id).then (r) ->
                ipcsend 'querypresence:result', r.presenceResult[0]
            , false, -> 1

    # no retry, only one outstanding call
    ipc.on 'setpresence', seqreq (ev, status=true) ->
        client.setpresence(status)
    , false, -> 1

    # no retry, only one outstanding call
    ipc.on 'setactiveclient', seqreq (ev, active, secs) ->
        client.setactiveclient active, secs
    , false, -> 1

    # watermarking is only interesting for the last of each conv_id
    # retry send and dedupe for each conv_id
    ipc.on 'updatewatermark', seqreq (ev, conv_id, time) ->
        client.updatewatermark conv_id, time
    , true, (ev, conv_id, time) -> conv_id

    # getentity is not super important, the client will try again when encountering
    # entities without photo_url. so no retry, but do execute all such reqs
    # ipc.on 'getentity', seqreq (ev, ids) ->
    #     client.getentitybyid(ids).then (r) -> ipcsend 'getentity:result', r
    # , false

    # we want to upload. in the order specified, with retry
    ipc.on 'uploadimage', seqreq (ev, spec) ->
        {path, conv_id, client_generated_id} = spec
        ipcsend 'uploadingimage', {conv_id, client_generated_id, path}
        client.uploadimage(path).then (image_id) ->

            delivery_medium = null

            client.sendchatmessage conv_id, null, image_id, null, client_generated_id, delivery_medium
    , true

    # we want to upload. in the order specified, with retry
    ipc.on 'uploadclipboardimage', seqreq (ev, spec) ->
        {pngData, conv_id, client_generated_id} = spec
        file = tmp.fileSync postfix: ".png"
        ipcsend 'uploadingimage', {conv_id, client_generated_id, path:file.name}
        Q.Promise (rs, rj) ->
            fs.writeFile file.name, pngData, plug(rs, rj)
        .then ->
            client.uploadimage(file.name)
        .then (image_id) ->
            delivery_medium = null
            client.sendchatmessage conv_id, null, image_id, null, client_generated_id, delivery_medium
        .then ->
            file.removeCallback()
    , true

    # retry only last per conv_id
    ipc.on 'setconversationnotificationlevel', seqreq (ev, conv_id, level) ->
        client.setconversationnotificationlevel conv_id, level
    , true, (ev, conv_id, level) -> conv_id

    # retry
    ipc.on 'deleteconversation', seqreq (ev, conv_id) ->
        console.log 'deletingconversation', conv_id if debug
        client.deleteconversation conv_id
        .then (r) ->
            console.log 'DEBUG: deleteconvsersation response: ', r if debug
            if r.response_header.status != 'OK'
                ipcsend 'message', i18n.__('conversation.delete_error:Error occured when deleting conversation')
    , true

    ipc.on 'removeuser', seqreq (ev, conv_id) ->
        client.removeuser conv_id
    , true

    # no retries, dedupe on conv_id
    ipc.on 'setfocus', seqreq (ev, conv_id) ->
        client.setfocus conv_id
        updateConversation(conv_id)
    , false, (ev, conv_id) -> conv_id

    # update conversation with metadata (for unread messages)
    updateConversation = (conv_id) ->
        client.getconversation conv_id, new Date(), 1, true
        .then (r) ->
            ipcsend 'getconversationmetadata:response', r

    ipc.on 'updateConversation', seqreq (ev, conv_id) ->
        updateConversation conv_id
    , false, (ev, conv_id) -> conv_id

    # no retries, dedupe on conv_id
    ipc.on 'settyping', seqreq (ev, conv_id, v) ->
        client.settyping conv_id, v
    , false, (ev, conv_id) -> conv_id

    ipc.on 'updatebadge', (ev, value) ->
        app.dock.setBadge(value) if app.dock

    ipc.on 'searchentities', (ev, query, max_results) ->
        promise = client.searchentities query, max_results
        promise.then (res) ->
            ipcsend 'searchentities:result', res
    ipc.on 'createconversation', (ev, ids, name, forcegroup=false) ->
        promise = client.createconversation ids, forcegroup
        conv = null
        promise.then (res) ->
            conv = res.conversation
            conv_id = conv.id.id
            client.renameconversation conv_id, name if name
        promise = promise.then (res) ->
            ipcsend 'createconversation:result', conv, name
    ipc.on 'adduser', (ev, conv_id, toadd) ->
        client.adduser conv_id, toadd # will automatically trigger membership_change
    ipc.on 'renameconversation', (ev, conv_id, newname) ->
        client.renameconversation conv_id, newname # will trigger conversation_rename

    # no retries, just dedupe on the ids
    ipc.on 'getentity', seqreq (ev, ids, data) ->
        client.getentitybyid(ids).then (r) ->
            ipcsend 'getentity:result', r, data
    , false, (ev, ids) -> ids.sort().join(',')

    # no retry, just one single request
    ipc.on 'syncallnewevents', seqreq (ev, time) ->
        console.log 'syncallnewevents: Asking hangouts to sync new events'
        client.syncallnewevents(time).then (r) ->
            ipcsend 'syncallnewevents:response', r
    , false, (ev, time) -> 1

    # no retry, just one single request
    ipc.on 'syncrecentconversations', syncrecent = seqreq (ev) ->
        console.log 'syncrecentconversations: Asking hangouts to sync recent conversations'
        client.syncrecentconversations().then (r) ->
            ipcsend 'syncrecentconversations:response', r
            # this is because we use syncrecent on reqinit (dev-mode
            # refresh). if we succeeded getting a response, we call it
            # connected.
            ipcsend 'connected'
    , false, (ev, time) -> 1

    # retry, one single per conv_id
    ipc.on 'getconversation', seqreq (ev, conv_id, timestamp, max) ->
        client.getconversation(conv_id, timestamp, max, true).then (r) ->
            ipcsend 'getconversation:response', r
    , false, (ev, conv_id, timestamp, max) -> conv_id

    ipc.on 'ctrl+w__pressed', ->
        mainWindow.hide()

    #    _      _     _                     _                                   _
    #   | |    (_)   | |                   | |                                 | |
    #   | |     _ ___| |_ ___ _ __         | |__   __ _ _ __   __ _  ___  _   _| |_ ___
    #   | |    | / __| __/ _ \ '_ \        | '_ \ / _` | '_ \ / _` |/ _ \| | | | __/ __|
    #   | |____| \__ \ ||  __/ | | |_ _ _  | | | | (_| | | | | (_| | (_) | |_| | |_\__ \
    #   |______|_|___/\__\___|_| |_(_|_|_) |_| |_|\__,_|_| |_|\__, |\___/ \__,_|\__|___/
    #                                                          __/ |
    #                                                         |___/
    # Listen on events from hangupsjs client.

    # propagate Hangout client events to the renderer
    require('./ui/events').forEach (n) ->
        client.on n, (e) ->
            log.debug 'DEBUG: Received event', n
            # client_conversation comes without metadata by default.
            #  We need it for unread count
            updateConversation e.conversation_id.id if (n == 'client_conversation')
            ipcsend n, e

    # Emitted when the window is about to close.
    # Hides the window if we're not force closing.
    #  IMPORTANT: moved to app.coffee
