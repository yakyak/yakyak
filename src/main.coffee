Client = require 'hangupsjs'
Q      = require 'q'
login  = require './login'
ipc    = require 'ipc'
fs     = require 'fs'
path   = require 'path'
appmenu = require './appmenu'

client = new Client()

app = require 'app'
BrowserWindow = require 'browser-window'

paths =
    rtokenpath:  path.normalize path.join app.getPath('userData'), 'refreshtoken.txt'
    cookiespath: path.normalize path.join app.getPath('userData'), 'cookies.json'
    chromecookie: path.normalize path.join app.getPath('userData'), 'Cookies'

client = new Client
    rtokenpath:  paths.rtokenpath
    cookiespath: paths.cookiespath

logout = ->
    promise = client.logout()
    plug = (rs, rj) -> (err, val) -> if err then rj(err) else rs(val)
    rm = (path) -> Q.Promise((rs, rj) -> fs.unlink(path, plug(rs, rj))).fail (err) ->
        if err.code == 'ENOENT' then null else Q.reject(err)
    promise = promise.then ->
        rm paths.chromecookie
    promise.fail (e) -> console.log e
    promise.then (res) ->
      argv = process.argv
      spawn = require('child_process').spawn
      spawn argv.shift(), argv,
        cwd: process.cwd
        env: process.env
        stdio: 'inherit'
      app.quit()
    return promise # like it matters

seqreq = require './seqreq'

mainWindow = null

# recorded events
recorded = []

# Quit when all windows are closed.
app.on 'window-all-closed', ->
    app.quit() # if (process.platform != 'darwin')

loadAppWindow = ->
    mainWindow.loadUrl 'file://' + __dirname + '/ui/index.html'

openDevTools = ->
    mainWindow?.openDevTools detach: true

# helper wait promise
wait = (t) -> Q.Promise (rs) -> setTimeout rs, t

app.on 'ready', ->

    # Create the browser window.
    mainWindow = new BrowserWindow {
        width: 620
        height: 420
        "min-width": 620
        "min-height": 420
    }

    appmenu.attach app, {openDevTools, logout}

    # and load the index.html of the app. this may however be yanked
    # away if we must do auth.
    loadAppWindow()

    # short hand
    ipcsend = (as...) ->  mainWindow.webContents.send as...

    # callback for credentials
    creds = ->
        prom = login(mainWindow)
        # reinstate app window when login finishes
        prom.then -> loadAppWindow()
        auth: -> prom

    # sends the init structures to the client
    sendInit = ->
        # we have no init data before the client has connected first
        # time.
        return unless client?.init?.self_entity
        ipcsend 'init',
            init: client.init
            recorded: recorded

    # keeps trying to connec the hangupsjs and communicates those
    # attempts to the client.
    do reconnect = ->
        client.connect(creds).then ->
            # send without being prompted on startup
            sendInit()

    # client deals with window sizing
    mainWindow.on 'resize', (ev) -> ipcsend 'resize', mainWindow.getSize()
    mainWindow.on 'moved',  (ev) -> ipcsend 'moved', mainWindow.getPosition()

    # whenever it fails, we try again
    client.on 'connect_failed', -> wait(3000).then -> reconnect()

    # when client requests (re-)init since the first init
    # object is sent as soon as possible on startup
    ipc.on 'reqinit', sendInit

    # sendchatmessage, executed sequentially and
    # retried if not sent successfully
    ipc.on 'sendchatmessage', seqreq (ev, msg) ->
        {conv_id, segs, client_generated_id, image_id, otr} = msg
        client.sendchatmessage(conv_id, segs, image_id, otr, client_generated_id).then (r) ->
            ipcsend 'sendchatmessage:result', r
        , true # do retry

    ipc.on 'setpresence', seqreq ->
        client.setpresence(true)
    , false # no retry

    # watermarking is only interesting for the last of each conv_id
    # retry send and dedupe for each conv_id
    ipc.on 'updatewatermark', seqreq (ev, conv_id, time) ->
        client.updatewatermark conv_id, time
    , true, (ev, conv_id, time) -> conv_id

    # getentity is not super important, the client will try again when encountering
    # entities without photo_url. so no retry, but do execute all such reqs
    ipc.on 'getentity', seqreq (ev, ids) ->
        client.getentitybyid(ids).then (r) -> ipcsend 'getentity:result', r
    , false

    # we want to upload. in the order specified, with retry
    ipc.on 'uploadimage', seqreq (ev, spec) ->
        {path, conv_id, client_generated_id} = spec
        client.uploadimage(path).then (image_id) ->
            client.sendchatmessage conv_id, null, image_id, null, client_generated_id
    , true

    # retry only last per conv_id
    ipc.on 'setconversationnotificationlevel', seqreq (ev, conv_id, level) ->
        client.setconversationnotificationlevel conv_id, level
    , true, (ev, conv_id, level) -> conv_id

    # retry
    ipc.on 'deleteconversation', seqreq (ev, conv_id) ->
        client.deleteconversation conv_id
    , true

    ipc.on 'searchentities', (ev, query, max_results) ->
        promise = client.searchentities query, max_results
        promise.then (res) ->
            ipcsend 'searchentities:result', res
    ipc.on 'createconversation', (ev, ids) ->
        promise = client.createconversation ids
        promise.then (res) ->
            conv = res.conversation
            ipcsend 'createconversation:result', conv
        promise.fail (err) -> console.log 'error', err

    ipc.on 'getentity', (ev, ids) -> client.getentitybyid(ids).then (r) ->
        ipcsend 'getentity:result', r

    # propagate these events to the renderer
    require('./ui/events').forEach (n) ->
        client.on n, (e) ->
            recorded.push [n, e]
            ipcsend n, e


    # Emitted when the window is closed.
    mainWindow.on 'closed', ->
        mainWindow = null
