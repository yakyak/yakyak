# expose trifl in global scope
trifl = require 'trifl'
trifl.expose window

# expose some selected tagg functions
trifl.tagg.expose window, ('ul li div span a i button table thead tbody tr td th'.split(' '))...

{applayout} = require './ui/views'

# tie layout to DOM
document.body.appendChild applayout.el
