# expose trifl in global scope
trifl = require 'trifl'
trifl.expose window

# expose some selected tagg functions
trifl.tagg.expose window, ('ul li div span a i b u s button
table thead tbody tr td th textarea'.split(' '))...

ipc = require 'ipc'

{applayout}    = require './views'

# tie layout to DOM
document.body.appendChild applayout.el

# wire all events to actions
ipc.on 'init', (e) -> action 'init', e
require('./events').forEach (n) -> ipc.on n, (e) -> action n, e

# init dispatcher/controller
require './dispatcher'
require './views/controller'
