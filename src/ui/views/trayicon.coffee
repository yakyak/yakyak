path = require 'path'
os   = require 'os'
i18n = require 'i18n'

{Menu, Tray, nativeImage} = require('electron').remote


if os.platform() == 'darwin'
    trayIcons =
        "read": path.join __dirname, '..', '..', 'icons', 'osx-icon-read-Template.png'
        "unread": path.join __dirname, '..', '..', 'icons', 'osx-icon-unread-Template.png'
        
else if process.env.XDG_CURRENT_DESKTOP && process.env.XDG_CURRENT_DESKTOP.match(/KDE/)
    # This is to work around a bug with electron apps + KDE not showing correct icon size.
    trayIcons =
      "read": path.join __dirname, '..', '..', 'icons', 'icon-read@20.png'
      "unread": path.join __dirname, '..', '..', 'icons', 'icon-unread@20.png'
     
else
    trayIcons =
        "read": path.join __dirname, '..', '..', 'icons', 'icon-read@8x.png'
        "unread": path.join __dirname, '..', '..', 'icons', 'icon-unread@8x.png'

tray = null

# TODO: this is all WIP
quit = ->

compact = (array) -> item for item in array when item

create = () ->
    tray = new Tray trayIcons["read"]
    tray.currentImage = 'read'
    tray.setToolTip i18n.__('title:YakYak - Hangouts Client')
    # Emitted when the tray icon is clicked
    tray.on 'click', -> action 'togglewindow'

destroy = ->
    tray.destroy() if tray
    tray = null

update = (unreadCount, viewstate) ->
    # update menu
    templateContextMenu = compact([
        {
          label: i18n.__ 'menu.view.tray.toggle_minimize:Toggle window show/hide'
          click: -> action 'togglewindow'
        }

        {
          label: i18n.__ "menu.view.tray.start_minimize:Start minimized to tray"
          type: "checkbox"
          checked: viewstate.startminimizedtotray
          click: -> action 'togglestartminimizedtotray'
        }

        {
          label: i18n.__ 'menu.view.notification.show:Show notifications'
          type: "checkbox"
          checked: viewstate.showPopUpNotifications
          # usage of already existing method and implements same logic
          #  as other toggle... methods
          click: -> action 'showpopupnotifications',
              !viewstate.showPopUpNotifications
        }

        {
            label: i18n.__ "menu.view.tray.close:Close to tray"
            type: "checkbox"
            checked: viewstate.closetotray
            click: -> action 'toggleclosetotray'
        }

        {
          label: i18n.__ 'menu.view.hide_dock:Hide Dock icon'
          type: 'checkbox'
          checked: viewstate.hidedockicon
          click: -> action 'togglehidedockicon'
        } if os.platform() == 'darwin'

        {
          label: i18n.__('menu.file.quit:Quit'),
          click: -> action 'quit'
        }
    ])

    contextMenu = Menu.buildFromTemplate templateContextMenu
    tray.setContextMenu contextMenu

    # update icon
    try
        if unreadCount > 0
            tray.setImage trayIcons["unread"] unless tray.currentImage == 'unread'
            tray.currentImage = 'unread'
        else
            tray.setImage trayIcons["read"] unless tray.currentImage == 'read'
            tray.currentImage = 'read'
    catch e
        console.log 'missing icons', e


module.exports = ({viewstate, conv}) ->
    if viewstate.showtray
        create() if not tray?
        update(conv.unreadTotal(), viewstate)
    else
        destroy() if tray
