# expose trifl in global scope
trifl = require 'trifl'
trifl.expose window

dispatcher = require './dispatcher'

# expose some selected tagg functions
trifl.tagg.expose window, ('ul li div span a i b u s button p label
input table thead tbody tr td th textarea br pass img h1 h2 h3 h4
hr'.split(' '))...

ipc = require 'ipc'

{applayout}    = require './views'
{viewstate}    = require './models'

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
ipc.on 'init', (e) -> dispatcher.init e
# events from hangupsjs
require('./events').forEach (n) -> ipc.on n, (e) -> action n, e
# response from getentity
ipc.on 'getentity:result', (r) -> action 'addentities', r.entities
ipc.on 'resize', (dim) -> action 'resize', dim
ipc.on 'moved', (pos)  -> action 'moved', pos
ipc.on 'searchentities:result', (r) ->
  action 'setsearchedentities', r.entity
ipc.on 'createconversation:result', (c, name) ->
    c.conversation_id = c.id # fix conversation payload
    c.name = name if name
    action 'createconversationdone', c
    action 'setstate', viewstate.STATE_NORMAL

# init dispatcher/controller
require './dispatcher'
require './views/controller'

# request init this is not happening when
# the server is just connecting, but for
# dev mode when we reload the page
action 'reqinit'
