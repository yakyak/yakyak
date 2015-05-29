# expose trifl in global scope
trifl = require 'trifl'
trifl.expose window

# expose some selected tagg functions
trifl.tagg.expose window, ('ul li div span a i button table thead tbody tr td th'.split(' '))...

ipc = require 'ipc'

{applayout}    = require './views'
{entity, conv} = require './models'

# tie layout to DOM
document.body.appendChild applayout.el

ipc.on 'init', (init) ->
    entity._initFromSelfEntity init.self_entity
    entity._initFromEntities init.entities
    conv._initFromConvStates init.conv_states
