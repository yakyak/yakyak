Client    = require 'hangupsjs'
Q         = require 'q'
login     = require './login'
ipc       = require('electron').ipcMain
fs        = require 'fs'
path      = require 'path'
tmp       = require 'tmp'
clipboard = require('electron').clipboard
Menu      = require('electron').menu
session = require('electron').session

tmp.setGracefulCleanup()

app = require('electron').app

BrowserWindow = require('electron').BrowserWindow

userData = path.normalize(app.getPath('userData'))
fs.mkdirSync(userData) if not fs.existsSync userData

paths =
    rtokenpath: path.join(userData, 'refreshtoken.txt')
    cookiespath: path.join(userData, 'cookies.json')
    chromecookie: path.join(userData, 'Cookies')
    configpath: path.join(userData, 'config.json')

client = new Client(
    rtokenpath: paths.rtokenpath
    cookiespath: paths.cookiespath
)

if fs.existsSync paths.chromecookie
    fs.unlinkSync paths.chromecookie

plug = (rs, rj) -> (err, val) -> if err then rj(err) else rs(val)

logout = ->
    promise = client.logout()
    promise.then (res) ->
      argv = process.argv
      spawn = require('child_process').spawn
      spawn argv.shift(), argv,
        cwd: process.cwd
        env: process.env
        stdio: 'inherit'
      quit()
    return promise # like it matters

seqreq = require './seqreq'

mainWindow = null

# Only allow a single active instance
shouldQuit = app.makeSingleInstance ->
    mainWindow.show() if mainWindow
    return true;

if shouldQuit
    app.quit();
    return;

# No more minimizing to tray, just close it
global.forceClose = false;
quit = ->
    global.forceClose = true;
    app.quit()
    return

app.on 'before-quit', ->
    global.forceClose = true;
    return

# For OSX show window main window if we've hidden it.
# https://github.com/electron/electron/blob/master/docs/api/app.md#event-activate-os-x
app.on 'activate', ->
    mainWindow.show()

loadAppWindow = ->
    mainWindow.loadURL 'file://' + __dirname + '/ui/index.html'

toggleWindowVisible = ->
    if mainWindow.isVisible() then mainWindow.hide() else mainWindow.show()

# helper wait promise
wait = (t) -> Q.Promise (rs) -> setTimeout rs, t

app.on 'ready', ->

    proxycheck = ->
        todo = [
           {url:'http://plus.google.com',  env:'HTTP_PROXY'}
           {url:'https://plus.google.com', env:'HTTPS_PROXY'}
        ]
        Q.all todo.map (t) -> Q.Promise (rs) ->
            console.log "resolving proxy #{t.url}"
            session.defaultSession.resolveProxy t.url, (proxyURL) ->
                console.log "resolved proxy #{proxyURL}"
                # Format of proxyURL is either "DIRECT" or "PROXY 127.0.0.1:8888"
                [_, purl] = proxyURL.split ' '
                process.env[t.env] ?= if purl then "http://#{purl}" else ""
                rs()

    # Create the browser window.
    mainWindow = new BrowserWindow {
        width: 730
        height: 590
        "min-width": 620
        "min-height": 420
        icon: path.join __dirname, 'icons', 'icon.png'
        show: true
        titleBarStyle: 'hidden-inset' if process.platform is 'darwin'
        autoHideMenuBar : true unless process.platform is 'darwin'
    }


    # and load the index.html of the app. this may however be yanked
    # away if we must do auth.
    loadAppWindow()

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

        loginWindow.on 'closed', quit

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
                  sendInit()
              else
                  syncrecent()
              reconnectCount++
          .catch (e) -> console.log 'error connecting', e

    # counter for reconnects
    reconnectCount = 0

    # whether to connect is dictated by the client.
    ipc.on 'hangupsConnect', ->
        console.log 'hconnect'
        reconnect()

    ipc.on 'hangupsDisconnect', ->
        console.log 'hdisconnect'
        reconnectCount = 0
        client.disconnect()

    # client deals with window sizing
    mainWindow.on 'resize', (ev) -> ipcsend 'resize', mainWindow.getSize()
    mainWindow.on 'move',  (ev) -> ipcsend 'move', mainWindow.getPosition()

    # whenever it fails, we try again
    client.on 'connect_failed', (e) ->
        console.log 'connect_failed', e
        wait(3000).then -> reconnect()

    # when client requests (re-)init since the first init
    # object is sent as soon as possible on startup
    ipc.on 'reqinit', -> syncrecent() if sendInit()

    # sendchatmessage, executed sequentially and
    # retried if not sent successfully
    messageQueue = Q()
    ipc.on 'sendchatmessage', (ev, msg) ->
        {conv_id, segs, client_generated_id, image_id, otr, message_action_type} = msg
        sendForSure = -> Q.promise (resolve, reject, notify) ->
            attempt = ->
                # console.log 'sendchatmessage', client_generated_id
                delivery_medium = null
                client.sendchatmessage(conv_id, segs, image_id, otr, client_generated_id, delivery_medium, message_action_type).then (r) ->
                      # console.log 'sendchatmessage:result', r?.created_event?.self_event_state?.client_generated_id
                      ipcsend 'sendchatmessage:result', r
                      resolve()
            attempt()
        messageQueue = messageQueue.then ->
            sendForSure()

    # sendchatmessage, executed sequentially and
    # retried if not sent successfully
    ipc.on 'querypresence', seqreq (ev, id) ->
        client.querypresence(id).then (r) ->
            ipcsend 'querypresence:result', r.presence_result[0]
        , false, -> 1

    ipc.on 'initpresence', (ev, l) ->
        for p, i in l when p != null
            client.querypresence(p.id).then (r) ->
                ipcsend 'querypresence:result', r.presence_result[0]
            , false, -> 1

    # no retry, only one outstanding call
    ipc.on 'setpresence', seqreq ->
        client.setpresence(true)
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
            client.sendchatmessage conv_id, null, image_id, null, client_generated_id
    , true

    # we want to upload. in the order specified, with retry
    ipc.on 'uploadclipboardimage', seqreq (ev, spec) ->
        {conv_id, client_generated_id} = spec
        file = tmp.fileSync postfix: ".png"
        pngData = clipboard.readImage().toPng()
        ipcsend 'uploadingimage', {conv_id, client_generated_id, path:file.name}
        Q.Promise (rs, rj) ->
            fs.writeFile file.name, pngData, plug(rs, rj)
        .then ->
            client.uploadimage(file.name)
        .then (image_id) ->
            client.sendchatmessage conv_id, null, image_id, null, client_generated_id
        .then ->
            file.removeCallback()
    , true

    # retry only last per conv_id
    ipc.on 'setconversationnotificationlevel', seqreq (ev, conv_id, level) ->
        client.setconversationnotificationlevel conv_id, level
    , true, (ev, conv_id, level) -> conv_id

    # retry
    ipc.on 'deleteconversation', seqreq (ev, conv_id) ->
        client.deleteconversation conv_id
    , true

    ipc.on 'removeuser', seqreq (ev, conv_id) ->
        client.removeuser conv_id
    , true

    # no retries, dedupe on conv_id
    ipc.on 'setfocus', seqreq (ev, conv_id) ->
        client.setfocus conv_id
    , false, (ev, conv_id) -> conv_id

    ipc.on 'appfocus', ->
      app.focus()
      if mainWindow.isVisible()
        mainWindow.focus()
      else
        mainWindow.show()

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
        console.log 'syncallnew'
        client.syncallnewevents(time).then (r) ->
            ipcsend 'syncallnewevents:response', r
    , false, (ev, time) -> 1

    # no retry, just one single request
    ipc.on 'syncrecentconversations', syncrecent = seqreq (ev) ->
        console.log 'syncrecent'
        client.syncrecentconversations().then (r) ->
            ipcsend 'syncrecentconversations:response', r
            # this is because we use syncrecent on reqinit (dev-mode
            # refresh). if we succeeded getting a response, we call it
            # connected.
            ipcsend 'connected'
    , false, (ev, time) -> 1

    # retry, one single per conv_id
    ipc.on 'getconversation', seqreq (ev, conv_id, timestamp, max) ->
        client.getconversation(conv_id, timestamp, max).then (r) ->
            ipcsend 'getconversation:response', r
    , false, (ev, conv_id, timestamp, max) -> conv_id

    ipc.on 'togglefullscreen', ->
      mainWindow.setFullScreen not mainWindow.isFullScreen()

    # bye bye
    ipc.on 'logout', logout

    ipc.on 'quit', quit

    # propagate these events to the renderer
    require('./ui/events').forEach (n) ->
        client.on n, (e) ->
            ipcsend n, e

    # Emitted when the window is about to close.
    # For OSX only hides the window if we're not force closing.
    mainWindow.on 'close', (ev) ->
        if process.platform == 'darwin'
            if mainWindow.isFullScreen()
                mainWindow.setFullScreen false
            if not global.forceClose
                ev.preventDefault()
                mainWindow.hide()
                return

        mainWindow = null
        quit()
