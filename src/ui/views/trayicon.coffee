remote = require 'remote'
Tray = remote.require 'tray'
Menu = remote.require 'menu'
path = require 'path'

trayIcons =
    "read": path.join __dirname, '..', '..', 'icons', 'icon.png'
    "unread": path.join __dirname, '..', '..', 'icons', 'icon-unread.png'
tray = null

# TODO: this is all WIP
quit = ->

create = () ->
    tray = new Tray trayIcons["read"]
    tray.setToolTip 'YakYak - Hangouts client'
    # Emitted when the tray icon is clicked
    tray.on 'clicked', -> action 'showwindow'
    
destroy = ->
    tray.destroy() if tray
    tray = null

update = (unreadCount, viewstate) ->
    # update menu
    templateContextMenu = [
        {
          label: 'Toggle minimize to tray'
          click: -> action 'togglewindow'
        }
        {
          label: "Start minimzed to tray"
          type: "checkbox"
          checked: viewstate.startminimizedtotray
          click: -> action 'togglestartminimizedtotray'
        }
        { 
          label: 'Hide Dock icon'
          type: 'checkbox'
          checked: viewstate.hidedockicon
          click: -> action 'togglehidedockicon'
        } if require('os').platform() == 'darwin'
        { label: 'Quit', click: -> action 'quit' }
    ]

    contextMenu = Menu.buildFromTemplate templateContextMenu
    tray.setContextMenu contextMenu

    # update icon
    try 
      if unreadCount > 0
          tray.setImage trayIcons["unread"]
      else
          tray.setImage trayIcons["read"]
    catch e
      console.log 'missing icons', e


module.exports = ({viewstate, conv}) ->
    if viewstate.showtray
      create() if not tray
      update(conv.unreadTotal(), viewstate)
    else
      destroy() if tray
