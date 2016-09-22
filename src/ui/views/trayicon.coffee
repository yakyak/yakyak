remote = require('electron').remote
Tray = remote.Tray
Menu = remote.Menu
path = require 'path'
os = require 'os'

trayIcons = null

if os.platform() == 'darwin'
    trayIcons =
        "read": path.join __dirname, '..', '..', 'icons', 'osx-icon-read-Template.png'
        "unread": path.join __dirname, '..', '..', 'icons', 'osx-icon-unread-Template.png'
else
    trayIcons =
        "read": path.join __dirname, '..', '..', 'icons', 'icon-read.png'
        "unread": path.join __dirname, '..', '..', 'icons', 'icon-unread.png'
tray = null

# TODO: this is all WIP
quit = ->

compact = (array) -> item for item in array when item

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
    templateContextMenu = compact([
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
            label: "Close to tray"
            type: "checkbox"
            checked: viewstate.closetotray
            click: -> action 'toggleclosetotray'
        }

        {
          label: 'Hide Dock icon'
          type: 'checkbox'
          checked: viewstate.hidedockicon
          click: -> action 'togglehidedockicon'
        } if os.platform() == 'darwin'

        { label: 'Quit', click: -> action 'quit' }
    ])

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
