path = require 'path'
os   = require 'os'
i18n = require 'i18n'

{ Menu, Tray, nativeImage } = require('electron').remote
{later} = require '../util'

if os.platform() == 'darwin'
    trayIconsPath =
        "read": path.join __dirname, '..', '..', 'icons', 'osx-icon-read-Template.png'
        "read-colorblind": path.join __dirname, '..', '..', 'icons', 'osx-icon-read-Template.png'
        "unread": path.join __dirname, '..', '..', 'icons', 'osx-icon-unread-Template.png'

else if process.env.XDG_CURRENT_DESKTOP && process.env.XDG_CURRENT_DESKTOP.match(/KDE/)
    # This is to work around a bug with electron apps + KDE not showing correct icon size.
    trayIconsPath =
      "read": path.join __dirname, '..', '..', 'icons', 'icon-read@20.png'
      "read-colorblind": path.join __dirname, '..', '..', 'icons', 'icon-read@20_blue.png'
      "unread": path.join __dirname, '..', '..', 'icons', 'icon-unread@20.png'

else
    trayIconsPath =
        "read": path.join __dirname, '..', '..', 'icons', 'icon-read@8x.png'
        "read-colorblind": path.join __dirname, '..', '..', 'icons', 'icon-read@8x_blue.png'
        "unread": path.join __dirname, '..', '..', 'icons', 'icon-unread@8x.png'

trayIcons =
  "read":            trayIconsPath["read"]
  "read-colorblind": trayIconsPath["read-colorblind"]
  "unread":          trayIconsPath["unread"]

tray = null

# TODO: this is all WIP
quit = ->

compact = (array) -> item for item in array when item

create = (viewstate) ->
    update(0, viewstate)

destroy = ->
    tray.destroy() if tray
    console.log('is Destroyed', tray.isDestroyed())
    tray = null

update = (unreadCount, viewstate) ->
    # update menu
    templateContextMenu = compact([
        {
          label: i18n.__ 'menu.view.tray.toggle_minimize:Toggle window show/hide'
          click_action: 'togglewindow'
        }

        {
          label: i18n.__ "menu.view.tray.start_minimize:Start minimized to tray"
          type: "checkbox"
          checked: viewstate.startminimizedtotray
          click_action: 'togglestartminimizedtotray'
        }

        {
          label: i18n.__ 'menu.view.notification.show:Show notifications'
          type: "checkbox"
          checked: viewstate.showPopUpNotifications
          # usage of already existing method and implements same logic
          #  as other toggle... methods
          click_action: 'togglepopupnotifications'
        }

        {
            label: i18n.__ "menu.view.tray.close:Close to tray"
            type: "checkbox"
            checked: viewstate.closetotray
            click_action: 'toggleclosetotray'
        }

        {
          label: i18n.__ 'menu.view.hide_dock:Hide Dock icon'
          type: 'checkbox'
          checked: viewstate.hidedockicon
          click_action: 'togglehidedockicon'
        } if os.platform() == 'darwin'

        {
          label: i18n.__('menu.file.quit:Quit'),
          click_action: 'quit'
        }
    ])

    # update icon
    try
        if unreadCount > 0
            later ->
                action 'settray', templateContextMenu, trayIcons["unread"], i18n.__('title:YakYak - Hangouts Client')
        else
            readIconName = if viewstate?.colorblind then 'read-colorblind' else 'read'
            later ->
                action 'settray', templateContextMenu, trayIcons[readIconName], i18n.__('title:YakYak - Hangouts Client')
    catch e
        console.log 'missing icons', e


module.exports = ({viewstate, conv}) ->
    if viewstate.showtray
        create(viewstate) if not tray?
        update(conv.unreadTotal(), viewstate)
    else
        destroy() if tray
