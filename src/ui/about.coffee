ipc  = require('electron').ipcRenderer
path = require 'path'

remote = require('electron').remote

window.onerror = (msg, url, lineNo, columnNo, error) ->
    hash = {msg, url, lineNo, columnNo, error}
    ipc.send 'errorInWindow', hash, "About"

aboutlayout = require './views/aboutlayout'

document.body.appendChild aboutlayout.el

link_out = (ev)->
    ev.preventDefault()
    address = e.currentTarget.getAttribute 'href'
    require('electron').shell.openExternal address
    false
