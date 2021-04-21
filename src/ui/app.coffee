ipc          = require('electron').ipcRenderer
clipboard    = require('electron').clipboard
path         = require('path')
autoLauncher = require('./util').autoLauncher

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

ipc.invoke('app:getpath', 'userData').then((res) ->
    global.USERDATA_DIR = res
)

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

# see if auto launching is enabled at a system level
autoLauncher.isEnabled().then((isEnabled) ->
    action 'initopenonsystemstartup', isEnabled
)

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
if not i18n.getLocales().includes viewstate.language
    viewstate.language = i18nOpts.defaultLocale

i18n.setLocale(viewstate.language)
#
ipc.send 'seti18n', i18nOpts, viewstate.language

# Set locale if exists, otherwise, keep 'en'
action 'changelanguage', viewstate.language
action 'setspellchecklanguage', viewstate.spellcheckLanguage

# does not update viewstate -- why? because locale can be recovered later
#   not the best reasoning :)

{applayout}       = require './views'

{conv} = require './models'

# show tray icon as soon as browser window appers
{ trayicon } = require './views/index'

contextmenu = require('./views/contextmenu')
require('./views/menu')(viewstate)

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
    #
    # remove initial error from DOM
    elToRemove = window.document.getElementById("error-b4-app")
    elToRemove.parentNode.removeChild(elToRemove)
    #
    # when yakyak becomes active, focus is automatically given
    #  to textarea
    ipc.on 'mainwindow.focus', () ->
        if viewstate.state == viewstate.STATE_NORMAL
            # focus on webContents
            ipc.send 'mainwindow.webcontents:focus'
            el = window.document.getElementById('message-input')
            # focus on specific element
            el?.focus()

    # hide menu bar in all platforms but darwin
    unless process.platform is 'darwin'
        # # Deprecated to BrowserWindow attribute
        # mainWindow.setAutoHideMenuBar(true)
        ipc.send 'mainwindow:setmenubarvisibility', false
    # handle the visibility of the window
    if viewstate.startminimizedtotray
        ipc.send 'mainwindow:hide'
    else
        ipc.send 'mainwindow:showifcred'

    #
    window.addEventListener 'unload', (ev) ->
        ev.preventDefault()

        forceclose = await ipc.invoke 'global:forceclose'
        if process.platform == 'darwin' && window?
            if window.isFullScreen()
                window.setFullScreen false
            if not forceclose
                window?.hide()
                return

        window = null
        action 'quit'

#
#
# This can be removed once windows10 supports NotoColorEmoji
#  (or the font supports Windows10)
#
if process.platform == 'win32'
    for stylesheet in window.document.styleSheets
        if stylesheet.href.match('app\.css')?
            for rule, i in stylesheet.cssRules
                if rule.type == 5 && rule.cssText.match('font-family: NotoColorEmoji;')?
                    stylesheet.deleteRule(i)
                    break
            break
#
#
# Get information on exceptions in main process
#  - Exceptions that were caught
#  - Window crashes
ipc.on 'expcetioninmain', (error) ->
    console.error (msg = "Possible fatal error on main process" +
        ", YakYak could stop working as expected."), error
    notr msg, {stay: 0}

ipc.on 'message', (msg) ->
    console.debug 'Message from main process:', msg
    notr msg

# wire up stuff from server
ipc.on 'init', (ev, data) -> dispatcher.init data
# events from hangupsjs
require('./events').forEach (n) -> ipc.on n, (ev, data) -> action n, data

# events from tray menu
ipc.on 'menuaction', (ev, name, p) ->
    console.debug('menuaction from main process', name)
    if p?
        action name, p...
    else
        action name

# response from getentity
ipc.on 'getentity:result', (ev, r, data) ->
    action 'addentities', r.entities, data?.add_to_conv

ipc.on 'getvideoinformation:result', (ev, conv_id, event_id, photo_id, result) ->
    action 'videoinformation', conv_id, event_id, photo_id, result

ipc.on 'resize', (ev, dim) -> action 'resize', dim

ipc.on 'move', (ev, pos)  -> action 'move', pos

ipc.on 'showerror', (ev, error) ->
    notr {
        html: "#{error}<br/><i style=\"font-size: .9em; color: gray\">(click to dismiss)</i>",
        stay: 0
    }

ipc.on 'searchentities:result', (ev, r) ->
    action 'setsearchedentities', r.entity
ipc.on 'createconversation:result', (ev, c, name) ->
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
    ipc.send 'mainwindow.webcontents:focus'
    # focus on textarea
    el = window.document.getElementById('message-input')
    el?.focus()

# register event listeners for on/offline
window.addEventListener 'online',  -> action 'wonline', true
window.addEventListener 'offline', -> action 'wonline', false

#
#
# Catch unresponsive events
ipc.on 'mainwindow.unresponsive', (error) ->
    notr msg = "Warning: YakYak is becoming unresponsive.",
        { id: 'unresponsive'}
    console.error 'Unresponsive event', msg
    ipc.send 'errorInWindow', 'Unresponsive window'

#
#
# Show a message
ipc.on 'mainwindow.responsive', () ->
    notr "Back to normal again!", { id: 'unresponsive'}

# Listen to close and quit events
window.addEventListener 'beforeunload', (e) ->
    if window.shouldQuit?
        return

    # we don't want to close here before retrieving
    # the force close value
    e.returnValue = false
    forceclose = await ipc.invoke 'global:forceclose'

    hide = (
        # Mac os and the dock have a special relationship
        (process.platform == 'darwin' && !viewstate.hidedockicon) ||
        # Handle the close to tray action
        viewstate.closetotray
    )

    if forceclose or not hide
        window.shouldQuit = true
        ipc.send 'mainwindow:close'
        return

    ipc.send 'mainwindow:hide'

window.addEventListener 'keypress', (e) ->
    if e.keyCode == 23 and e.ctrlKey
      ipc.send 'ctrl+w__pressed', ''

ipc.on 'mainwindow.webcontents.context-menu', (event, params) ->
    canShow = [viewstate.STATE_NORMAL,
               viewstate.STATE_ADD_CONVERSATION,
               viewstate.STATE_ABOUT].includes(viewstate.state)
    if canShow
        ipc.send 'menu:popup', contextmenu(params, viewstate)


# tell the startup state
action 'wonline', window.navigator.onLine
