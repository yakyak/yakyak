ipc       = require('electron').ipcRenderer
path = require 'path'

remote = require('electron').remote

trifl = require 'trifl'

# expose some selected tagg functions
trifl.tagg.expose window, ('ul li div span a i b u s button p label
input table thead tbody tr td th textarea br pass img h1 h2 h3 h4
hr em'.split(' '))...

{applayout, aboutlayout} = require './views'

document.body.appendChild aboutlayout.el

link_out = (ev)->
    ev.preventDefault()
    address = e.currentTarget.getAttribute 'href'
    require('electron').shell.openExternal address
    false
