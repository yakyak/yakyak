# expose trifl in global scope
trifl = require 'trifl'
trifl.expose window

dispatcher = require './dispatcher'

# expose some selected tagg functions
trifl.tagg.expose window, ('ul li div span a i b u s button
table thead tbody tr td th textarea br pass img'.split(' '))...

ipc = require 'ipc'

{applayout}    = require './views'

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

# request init this is not happening when
# the server is just connecting, but for
# dev mode when we reload the page
ipc.send 'reqinit'

# wire up stuff from server
ipc.on 'init', (e) -> dispatcher.init e
# events from hangupsjs
require('./events').forEach (n) -> ipc.on n, (e) -> action n, e
# response from getentity
ipc.on 'getentity:result', (r) -> action 'addentities', r.entities

# init dispatcher/controller
require './dispatcher'
require './views/controller'
