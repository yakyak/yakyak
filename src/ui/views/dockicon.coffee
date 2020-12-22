ipc  = require('electron').ipcRenderer
# calling show multiple times makes the osx app flash
# therefore we remember here if the dock is already shown
# and we avoid re-calling app.dock.show() multiple times
dockAlreadyVisible = true

module.exports = (viewstate) ->
  if require('os').platform() isnt 'darwin' then return

  if viewstate.hidedockicon and (dockAlreadyVisible is true)
    console.log 'hiding dock'
    ipc.send 'app.dock:hide'
    dockAlreadyVisible = false

  if not viewstate.hidedockicon and (dockAlreadyVisible is false)
    console.log 'showing dock'
    ipc.send 'app.dock:show'
    dockAlreadyVisible = true
