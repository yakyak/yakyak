app = require('remote').require('app')

module.exports = (viewstate) ->
  if require('os').platform() isnt 'darwin' then return
  if viewstate.hidedockicon then app.dock.hide() else app.dock.show()