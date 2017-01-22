ipc       = require('electron').ipcRenderer
clipboard = require('electron').clipboard
path = require('path')

[drive, path_parts...] = path.normalize(__dirname).split(path.sep)
global.YAKYAK_ROOT_DIR = [drive, path_parts.map(encodeURIComponent)...].join('/')

# expose trifl in global scope
trifl = require 'trifl'
trifl.expose window

# in app notification system
window.notr = require 'notr'
notr.defineStack 'def', 'body', {top:'3px', right:'15px'}

# init trifl dispatcher
dispatcher = require './dispatcher'

remote = require('electron').remote

window.onerror = (msg, url, lineNo, columnNo, error) ->
    hash = {msg, url, lineNo, columnNo, error}
    ipc.send 'errorInWindow', hash

# expose some selected tagg functions
trifl.tagg.expose window, ('ul li div span a i b u s button p label
input table thead tbody tr td th textarea br pass img h1 h2 h3 h4
hr em'.split(' '))...

#
# Translation support
window.i18n = require('i18n')
# This had to be antecipated, as i18n requires viewstate
#  and applayout requires i18n
{viewstate} = require './models'

#
# Configuring supporting languages here
i18nOpts = {
    directory: path.join __dirname, '..', 'locales'
    defaultLocale: 'en' # fallback
    objectNotation: true
}
#
i18n.configure i18nOpts
#
# force initialize
if i18n.getLocales().includes viewstate.language
    i18n.setLocale(viewstate.language)
#
ipc.send 'seti18n', i18nOpts, viewstate.language

# Set locale if exists, otherwise, keep 'en'
action 'changelanguage', viewstate.language
# does not update viewstate -- why? because locale can be recovered later
#   not the best reasoning :)

{applayout}       = require './views'

{conv} = require './models'

# show tray icon as soon as browser window appers
{ trayicon } = require './views/index'

contextmenu = require('./views/contextmenu')
require('./views/menu')(viewstate)

# tie layout to DOM

# restore last position of window
currentWindow = remote.getCurrentWindow()

currentWindow.setPosition viewstate.pos...

document.body.appendChild applayout.el

# intercept every event we listen to
# to make an 'alive' action to know
# the server is alive
do ->
    ipcon = ipc.on.bind(ipc)
    ipc.on = (n, fn) ->
        ipcon n, (as...) ->
            action 'alive', Date.now()
            fn as...

# called when window is ready to show
#  note: could not use event here, as it must be defined
#  before
ipc.on 'ready-to-show', () ->
    # get window object
    mainWindow = remote.getCurrentWindow()
    #
    # when yakyak becomes active, focus is automatically given
    #  to textarea
    mainWindow.on 'focus', () ->
        if viewstate.state == viewstate.STATE_NORMAL
            # focus on webContents
            mainWindow.webContents.focus()
            el = window.document.getElementById('message-input')
            # focus on specific element
            el?.focus()

    # hide menu bar in all platforms but darwin
    unless process.platform is 'darwin'
        mainWindow.setAutoHideMenuBar(true)
        mainWindow.setMenuBarVisibility(false)
    # handle the visibility of the window
    if viewstate.startminimizedtotray
        mainWindow.hide()
    else if !remote.getGlobal('windowHideWhileCred')? ||
             remote.getGlobal('windowHideWhileCred') != true
        mainWindow.show()

    #
    window.addEventListener 'unload', (ev) ->
        if process.platform == 'darwin' && window?
            if window.isFullScreen()
                window.setFullScreen false
            if not remote.getGlobal('forceClose')
                ev.preventDefault()
                window?.hide()
                return

        window = null
        action 'quit'

#
#
# Get information on exceptions in main process
#  - Exceptions that were caught
#  - Window crashes
ipc.on 'expcetioninmain', (error) ->
    console.log (msg = "Possible fatal error on main process" +
        ", YakYak could stop working as expected."), error
    notr msg, {stay: 0}

# wire up stuff from server
ipc.on 'init', (ev, data) -> dispatcher.init data
# events from hangupsjs
require('./events').forEach (n) -> ipc.on n, (ev, data) -> action n, data
# response from getentity
ipc.on 'getentity:result', (ev, r, data) ->
    action 'addentities', r.entities, data?.add_to_conv

ipc.on 'resize', (ev, dim) -> action 'resize', dim

ipc.on 'move', (ev, pos)  -> action 'move', pos
ipc.on 'searchentities:result', (ev, r) ->
    action 'setsearchedentities', r.entity
ipc.on 'createconversation:result', (ev, c, name) ->
    c.conversation_id = c.id # fix conversation payload
    c.name = name if name
    action 'createconversationdone', c
    action 'setstate', viewstate.STATE_NORMAL
ipc.on 'syncallnewevents:response', (ev, r) -> action 'handlesyncedevents', r
ipc.on 'syncrecentconversations:response', (ev, r) -> action 'handlerecentconversations', r
ipc.on 'getconversation:response', (ev, r) -> action 'handlehistory', r
#
# gets metadata from conversation after setting focus
ipc.on 'getconversationmetadata:response', (ev, r) ->
    action 'handleconversationmetadata', r
ipc.on 'uploadingimage', (ev, spec) -> action 'uploadingimage', spec
ipc.on 'querypresence:result', (ev, r) -> action 'setpresence', r

# init dispatcher/controller
require './dispatcher'
require './views/controller'

# request init this is not happening when
# the server is just connecting, but for
# dev mode when we reload the page
action 'reqinit'

#
#
# Listen to paste event and paste to message textarea
#
#  The only time when this event is not triggered, is when
#   the event is triggered from the message-area itself
#
document.addEventListener 'paste', (e) ->
    if not clipboard.readImage().isEmpty() and not clipboard.readText()
        action 'onpasteimage'
        e.preventDefault()
    # focus on web contents
    mainWindow = remote.getCurrentWindow()
    mainWindow.webContents.focus()
    # focus on textarea
    el = window.document.getElementById('message-input')
    el?.focus()

# register event listeners for on/offline
window.addEventListener 'online',  -> action 'wonline', true
window.addEventListener 'offline', -> action 'wonline', false

#
#
# Catch unresponsive events
remote.getCurrentWindow().on 'unresponsive', (error) ->
    notr msg = "Warning: YakYak is becoming unresponsive.",
        { id: 'unresponsive'}
    console.log 'Unresponsive event', msg
    ipc.send 'errorInWindow', 'Unresponsive window'

#
#
# Show a message
remote.getCurrentWindow().on 'responsive', () ->
    notr "Back to normal again!", { id: 'unresponsive'}

# Listen to close and quit events
window.addEventListener 'beforeunload', (e) ->
    if remote.getGlobal('forceClose')
        return

    hide = (
        # Mac os and the dock have a special relationship
        (process.platform == 'darwin' && !viewstate.hidedockicon) ||
        # Handle the close to tray action
        viewstate.closetotray
    )

    if hide
        e.returnValue = false
        remote.getCurrentWindow().hide()
    return

currentWindow.webContents.on 'context-menu', (e, params) ->
    e.preventDefault()
    canShow = [viewstate.STATE_NORMAL,
               viewstate.STATE_ADD_CONVERSATION].includes(viewstate.state)
    if canShow
        contextmenu(params, viewstate).popup remote.getCurrentWindow()

# tell the startup state
action 'wonline', window.navigator.onLine

script = document.createElement('script')
script.src = 'http://twemoji.maxcdn.com/2/twemoji.min.js'
document.head.appendChild(script)
