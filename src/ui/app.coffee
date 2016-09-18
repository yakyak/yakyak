ipc       = require('electron').ipcRenderer

# expose trifl in global scope
trifl = require 'trifl'
trifl.expose window

# in app notification system
window.notr = require 'notr'
notr.defineStack 'def', 'body', {top:'3px', right:'15px'}

# init trifl dispatcher
dispatcher = require './dispatcher'

remote = require('electron').remote

# expose some selected tagg functions
trifl.tagg.expose window, ('ul li div span a i b u s button p label
input table thead tbody tr td th textarea br pass img h1 h2 h3 h4
hr'.split(' '))...

{applayout}       = require './views'
{viewstate, conv} = require './models'

contextmenu = require('./views/contextmenu')
require('./views/menu')(viewstate)
if viewstate.startminimizedtotray
  remote.getCurrentWindow().hide()

# tie layout to DOM

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
ipc.on 'uploadingimage', (ev, spec) -> action 'uploadingimage', spec
ipc.on 'querypresence:result', (ev, r) -> action 'setpresence', r

# init dispatcher/controller
require './dispatcher'
require './views/controller'

# request init this is not happening when
# the server is just connecting, but for
# dev mode when we reload the page
action 'reqinit'

# register event listeners for on/offline
window.addEventListener 'online',  -> action 'wonline', true
window.addEventListener 'offline', -> action 'wonline', false

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

window.addEventListener 'contextmenu', ((e) ->
      e.preventDefault()
      contextmenu.popup remote.getCurrentWindow()
      return
), false

# tell the startup state
action 'wonline', window.navigator.onLine

if process.platform == 'win32'
    script = document.createElement('script')
    script.src = 'http://twemoji.maxcdn.com/2/twemoji.min.js'
    document.head.appendChild(script)
