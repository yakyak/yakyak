# expose trifl in global scope
trifl = require 'trifl'
trifl.expose window

dispatcher = require './dispatcher'

# expose some selected tagg functions
trifl.tagg.expose window, ('ul li div span a i b u s button
table thead tbody tr td th textarea br'.split(' '))...

ipc = require 'ipc'

{applayout}    = require './views'

# tie layout to DOM
document.body.appendChild applayout.el

# wire all events to actions
ipc.on 'init', (e) -> dispatcher.init e
require('./events').forEach (n) -> ipc.on n, (e) -> action n, e

# request init
ipc.send 'reqinit'

# init dispatcher/controller
require './dispatcher'
require './views/controller'
