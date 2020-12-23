ipc          = require('electron').ipcRenderer

{notificationCenterSupportsSound} = require '../util'

platform = require('os').platform()
# to reduce number of == comparisons
isDarwin = platform == 'darwin'
isLinux = platform == 'linux'
isNotDarwin = platform != 'darwin'

# true if it does, false otherwise
notifierSupportsSound = notificationCenterSupportsSound()

acceleratorMap = {
    # MacOSX specific
    hideyakyak: { default: 'CmdOrCtrl+H' }
    hideothers: { default: '', darwin:'Command+Shift+H' }
    showall: { default: '', darwin:'' }
    openinspector: { default: 'CmdOrCtrl+Alt+I' }
    close: { default: '', darwin:'Command+W' }
    # Common shortcuts
    quit: { default: 'CmdOrCtrl+Q' }
    zoomin: { default: 'CmdOrCtrl+Plus' }
    toggleimagepreview: { default: 'CmdOrCtrl+P' }
    # Platform specific
    previousconversation: { default: 'Ctrl+K', darwin:'Ctrl+Shift+Tab' }
    nextconversation:  { default: 'Ctrl+J', darwin:'Ctrl+Tab' }
    newconversation: { default: 'CmdOrCtrl+N' }
    conversation1: { default: 'Alt+1', darwin:'Command+1' }
    conversation2: { default: 'Alt+2', darwin:'Command+2' }
    conversation3: { default: 'Alt+3', darwin:'Command+3' }
    conversation4: { default: 'Alt+4', darwin:'Command+4' }
    conversation5: { default: 'Alt+5', darwin:'Command+5' }
    conversation6: { default: 'Alt+6', darwin:'Command+6' }
    conversation7: { default: 'Alt+7', darwin:'Command+7' }
    conversation8: { default: 'Alt+8', darwin:'Command+8' }
    conversation9: { default: 'Alt+9', darwin:'Command+9' }
}

getAccelerator = (key) ->
    if (acceleratorMap[key][platform])?
        acceleratorMap[key][platform]
    else
        acceleratorMap[key]['default']

templateYakYak = (viewstate) ->

    [
        {
            label: i18n.__ 'menu.help.about.title:About YakYak'
            action: {name: 'show-about'}
        } if isDarwin
        {
            type: 'checkbox'
            label: i18n.__('menu.help.about.startup:Open on Startup')
            checked: viewstate.openOnSystemStartup
            action: {name: 'openonsystemstartup', params: [':checked']}
        }
        #{ type: 'separator' }
        # { label: 'Preferences...', accelerator: 'Command+,',
        # click: => delegate.openConfig() }
        { type: 'separator' } if isDarwin
        {
            label: i18n.__ 'menu.file.hide:Hide YakYak'
            accelerator: getAccelerator('hideyakyak')
            role: if isDarwin then 'hide' else 'minimize'
        }
        {
            label: i18n.__ 'menu.file.hide_others:Hide Others'
            accelerator: getAccelerator('hideothers')
            role: 'hideothers'
        } if isDarwin
        {
            label: i18n.__ "menu.file.show:Show All"
            role: 'unhide'
        } if isDarwin # old show all
        { type: 'separator' }
        {
          label: i18n.__ 'menu.file.inspector:Open Inspector'
          accelerator: getAccelerator('openinspector')
          action: {name: 'devtools'}
        }
        { type: 'separator' }
        {
            label: i18n.__('menu.file.logout:Logout')
            action: {name: 'logout'}
            enabled: viewstate.loggedin
        }
        {
            label: i18n.__('menu.file.quit:Quit')
            accelerator: getAccelerator('quit')
            action: {name: 'quit'}
        }
    ].filter (n) -> n != undefined

templateEdit = (viewstate) ->
    languages = for loc in i18n.getLocales()
        if loc.length < 2
            continue
        {
            label: i18n.getCatalog(loc).__MyLocaleLanguage__
            type: 'radio'
            checked: viewstate.language == loc
            value: loc
            action: {name: 'changelanguage', params: [':value']}
        }
    languages = languages.filter (n) -> n != undefined
    [
        {
            label: i18n.__ 'menu.edit.undo:Undo'
            role: 'undo'
        }
        {
            label: i18n.__ 'menu.edit.redo:Redo'
            role: 'redo'
        }
        { type: 'separator' }
        {
            label: i18n.__ 'menu.edit.cut:Cut'
            role: 'cut'
        }
        {
            label: i18n.__ 'menu.edit.copy:Copy'
            role: 'copy'
        }
        {
            label: i18n.__ 'menu.edit.paste:Paste'
            role: 'paste'
        }
        {
            label: i18n.__ 'menu.edit.select_all:Select All'
            role: 'selectall'
        }
        { type: 'separator' }
        {
            label: i18n.__('menu.edit.language:Language')
            submenu: languages
        }
        {
            label: i18n.__('menu.edit.dateformat:Use system date format')
            type: 'checkbox'
            checked: viewstate.useSystemDateFormat
            enabled: true
            action: {name: 'setusesystemdateformat', params: [':checked']}
        }

    ].filter (n) -> n != undefined

templateView = (viewstate) ->
    [
        {
            label: i18n.__('menu.view.conversation.title:Conversation List')
            submenu: [
              {
                  type: 'checkbox'
                  label: i18n.__('menu.view.conversation.thumbnails.show:Show Thumbnails')
                  checked: viewstate.showConvThumbs
                  enabled: viewstate.loggedin
                  action: {name: 'showconvthumbs', params: [':checked']}
              }
              {
                  type: 'checkbox'
                  label: i18n.__('menu.view.conversation.thumbnails.only:Show Thumbnails Only')
                  checked:viewstate.showConvMin
                  enabled: viewstate.loggedin
                  action: {name: 'showconvmin', params: [':checked']}
              }
              {
                  type: 'checkbox'
                  label: i18n.__('menu.view.conversation.thumbnails.animated:Show Animated Thumbnails')
                  checked:viewstate.showAnimatedThumbs
                  enabled: viewstate.loggedin
                  action: {name: 'showanimatedthumbs', params: [':checked']}
              }
              {
                  type: 'checkbox'
                  label: i18n.__('menu.view.conversation.timestamp:Show Conversation Timestamp')
                  checked:viewstate.showConvTime
                  enabled: viewstate.loggedin && !viewstate.showConvMin
                  action: {name: 'showconvtime', params: [':checked']}
              }
              {
                  type: 'checkbox'
                  label: i18n.__('menu.view.conversation.last:Show Conversation Last Message')
                  checked:viewstate.showConvLast
                  enabled: viewstate.loggedin && !viewstate.showConvMin
                  action: {name: 'showconvlast', params: [':checked']}
              }
          ]
        }
        {
            label: i18n.__ 'menu.view.notification.title:Pop-Up Notification'
            submenu: [
                {
                    type: 'checkbox'
                    label: i18n.__('menu.view.notification.show:Show notifications')
                    checked: viewstate.showPopUpNotifications
                    enabled: viewstate.loggedin
                    action: {name: 'showpopupnotifications', params: [':checked']}
                }, {
                    type: 'checkbox'
                    label: i18n.__('menu.view.notification.message:Show message in notifications')
                    checked: viewstate.showMessageInNotification
                    enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                    action: {name: 'showmessageinnotification', params: [':checked']}
                }, {
                    type: 'checkbox'
                    label: i18n.__('menu.view.notification.username:Show username in notifications')
                    checked: viewstate.showUsernameInNotification
                    enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                    action: {name: 'showusernameinnotification', params: [':checked']}
                }
                {
                  type: 'checkbox'
                  label: i18n.__ (if isDarwin then 'menu.view.notification.avatar:Show user avatar icon in notifications' else 'menu.view.notification.icon:Show YakYak icon in notifications')
                  enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                  checked: viewstate.showIconNotification
                  action: {name: 'showiconnotification', params: [':checked']}
                }
                {
                  type: 'checkbox'
                  label: i18n.__('menu.view.notification.mute:Disable sound in notifications')
                  checked: viewstate.muteSoundNotification
                  enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                  action: {name: 'mutesoundnotification', params: [':checked']}
                }
                # Only show option if notifier backend supports sound, otherwise custom sound is always used
                {
                  type: 'checkbox'
                  label: i18n.__('menu.view.notification.custom_sound:Use YakYak custom sound for notifications')
                  checked: viewstate.forceCustomSound
                  enabled: viewstate.loggedin && viewstate.showPopUpNotifications && !viewstate.muteSoundNotification
                  action: {name: 'forcecustomsound', params: [':checked']}
                } if notifierSupportsSound
            ].filter (n) -> n != undefined
        }
        {
            type: 'checkbox'
            label: i18n.__('menu.view.emoji:Convert text to emoji')
            checked: viewstate.convertEmoji
            enabled: viewstate.loggedin
            action: {name: 'convertemoji', params: [':checked']}
        }
        {
            type: 'checkbox'
            label: i18n.__('menu.view.suggestemoji:Suggest emoji on typing')
            checked: viewstate.suggestEmoji
            enabled: viewstate.loggedin
            action: {name: 'suggestemoji', params: [':checked']}
        }
        {
            type: 'checkbox'
            accelerator: getAccelerator('toggleimagepreview')
            label: i18n.__('menu.view.showimagepreview:Show image preview')
            checked: viewstate.showImagePreview
            enabled: viewstate.loggedin
            action: {name: 'showimagepreview', params: [':checked']}
        }
        {
            label: i18n.__('menu.view.color_scheme.title:Color Scheme')
            submenu: [
              {
                  label: i18n.__('menu.view.color_scheme.default:Original')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'default'
                  action: {name: 'changetheme', params: ['default']}
              }
              {
                  label: i18n.__('menu.view.color_scheme.blue:Blue')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'blue'
                  action: {name: 'changetheme', params: ['blue']}
              }
              {
                  label: i18n.__('menu.view.color_scheme.dark:Dark')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'dark'
                  action: {name: 'changetheme', params: ['dark']}
              }
              {
                  label: i18n.__('menu.view.color_scheme.darker:Darker')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'darker'
                  action: {name: 'changetheme', params: ['darker']}
              }
              {
                  label: i18n.__('menu.view.color_scheme.material:Material')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'material'
                  action: {name: 'changetheme', params: ['material']}
              }
              {
                  label: i18n.__('menu.view.color_scheme.pop:Pop')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'pop'
                  action: {name: 'changetheme', params: ['pop']}
              }
              {
                  label: i18n.__('menu.view.color_scheme.gruvy:Gruvy')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'gruvy'
                  action: {name: 'changetheme', params: ['gruvy']}
               }
            ]
        }
        {
            label: i18n.__('menu.view.font.title:Font Size')
            submenu: [
              {
                  label: i18n.__('menu.view.font.extra_small:Extra Small')
                  type: 'radio'
                  checked: viewstate.fontSize == 'x-small'
                  action: {name: 'changefontsize', params: ['x-small']}
              }
              {
                  label: i18n.__('menu.view.font.small:Small')
                  type: 'radio'
                  checked: viewstate.fontSize == 'small'
                  action: {name: 'changefontsize', params: ['small']}
              }
              {
                  label: i18n.__('menu.view.font.medium:Medium')
                  type: 'radio'
                  checked: viewstate.fontSize == 'medium'
                  action: {name: 'changefontsize', params: ['medium']}
              }
              {
                  label: i18n.__('menu.view.font.large:Large')
                  type: 'radio'
                  checked: viewstate.fontSize == 'large'
                  action: {name: 'changefontsize', params: ['large']}
              }
              {
                  label: i18n.__('menu.view.font.extra_large:Extra Large')
                  type: 'radio'
                  checked: viewstate.fontSize == 'x-large'
                  action: {name: 'changefontsize', params: ['x-large']}
              }
            ]
        }
        {
            label: i18n.__ 'menu.view.fullscreen:Toggle Fullscreen'
            role: 'togglefullscreen'
        }
        {
            label: i18n.__ 'menu.view.zoom.in:Zoom in'
            # seee https://github.com/atom/electron/issues/1507
            role: 'zoomin'
        }
        {
            label: i18n.__ 'menu.view.zoom.out:Zoom out'
            role: 'zoomout'
        }
        {
            label: i18n.__ 'menu.view.zoom.reset:Actual size'
            role: 'resetzoom'
        }
        { type: 'separator' }
        {
            label: i18n.__('menu.view.conversation.new:New conversation')
            accelerator: getAccelerator('newconversation')
            enabled: viewstate.loggedin
            action: {name: 'addconversation'}
        }
        {
            label: i18n.__('menu.view.conversation.previous:Previous Conversation')
            accelerator: getAccelerator('previousconversation')
            enabled: viewstate.loggedin
            action: {name: 'selectNextConv', params: [-1]}
        }
        {
            label: i18n.__('menu.view.conversation.next:Next Conversation')
            accelerator: getAccelerator('nextconversation')
            enabled: viewstate.loggedin
            action: {name: 'selectNextConv', params: [+1]}
        }
        {
            label: i18n.__('menu.view.conversation.select:Select Conversation')
            enabled: viewstate.loggedin
            submenu: [
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 1)
                  accelerator: getAccelerator('conversation1')
                  action: {name: 'selectConvIndex', params: [0]}
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 2)
                  accelerator: getAccelerator('conversation2')
                  action: {name: 'selectConvIndex', params: [1]}
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 3)
                  accelerator: getAccelerator('conversation3')
                  action: {name: 'selectConvIndex', params: [2]}
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 4)
                  accelerator: getAccelerator('conversation4')
                  action: {name: 'selectConvIndex', params: [3]}
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 5)
                  accelerator: getAccelerator('conversation5')
                  action: {name: 'selectConvIndex', params: [4]}
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 6)
                  accelerator: getAccelerator('conversation6')
                  action: {name: 'selectConvIndex', params: [5]}
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 7)
                  accelerator: getAccelerator('conversation7')
                  action: {name: 'selectConvIndex', params: [6]}
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 8)
                  accelerator: getAccelerator('conversation8')
                  action: {name: 'selectConvIndex', params: [7]}
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 9)
                  accelerator: getAccelerator('conversation9')
                  action: {name: 'selectConvIndex', params: [8]}
              }
            ]
        }
        { type: 'separator' }
        {
            label: i18n.__('menu.view.tray.main:Tray icon')
            submenu: [
                {
                    label: i18n.__('menu.view.tray.show_tray:Show tray icon')
                    type: 'checkbox'
                    enabled: not viewstate.hidedockicon
                    checked:  viewstate.showtray
                    action: {name: 'toggleshowtray'}
                }
                {
                  label: i18n.__ "menu.view.tray.start_minimize:Start minimized to tray"
                  type: "checkbox"
                  enabled: viewstate.showtray
                  checked: viewstate.startminimizedtotray
                  action: {name: 'togglestartminimizedtotray'}
                }
                {
                    label: i18n.__ "menu.view.tray.close:Close to tray"
                    type: "checkbox"
                    enabled: viewstate.showtray
                    checked: viewstate.closetotray
                    action: {name: 'toggleclosetotray'}
                }
                {
                    label: i18n.__('menu.view.tray.colorblind:Use colorblind tray icon')
                    type: 'checkbox'
                    checked:  viewstate.colorblind
                    action: {name: 'togglecolorblind'}
                }
            ]
        }
        {
          label: i18n.__('menu.view.escape.title:Escape key behavior')
          submenu: [
              {
                  label: i18n.__('menu.view.escape.hide:Hides window')
                  type: 'radio'
                  enabled: viewstate.showtray
                  checked: viewstate.showtray && !viewstate.escapeClearsInput
                  action: {name: 'setescapeclearsinput', params: [false]}
              }
              {
                  label: i18n.__('menu.view.escape.clear:Clears input') + if !viewstate.showtray then " (#{i18n.__ 'menu.view.escape.default:default when tray is not showing'})" else ''
                  type: 'radio'
                  enabled: viewstate.showtray
                  checked: !viewstate.showtray || viewstate.escapeClearsInput
                  action: {name: 'setescapeclearsinput', params: [true]}
              }
          ]
        }
        {
            label: i18n.__('menu.view.hide_dock:Hide Dock icon')
            type: 'checkbox'
            enabled: viewstate.showtray
            checked:  viewstate.hidedockicon
            action: {name: 'togglehidedockicon'}
        } if isDarwin
    ].filter (n) -> n != undefined

templateWindow = (viewstate) -> [
    {
        label: i18n.__ 'menu.window.minimize:Minimize'
        role: 'minimize'
    }
    {
        label: i18n.__('menu.window.close:Close')
        accelerator: getAccelerator('close')
        role: 'close'
    }
    {
        label: i18n.__ 'menu.view.tray.toggle_minimize:Toggle window show/hide'
        action: {name: 'togglewindow'}
    }
    { type: 'separator' }
    {
        label: i18n.__('menu.window.front:Bring All to Front')
        role: 'front'
    }
]

# note: electron framework currently does not support undefined Menu
#  entries, which requires a filter for undefined at menu/submenu entry
#  to remove them
#
#  [.., undefined, ..., undefined,.. ].filter (n) -> n != undefined
#
templateMenu = (viewstate) ->
    [
        {
            label: ''
        } if isLinux
        {
            label: i18n.__ 'menu.file.title:YakYak'
            submenu: templateYakYak viewstate
        }
        {
            label: i18n.__ 'menu.edit.title:Edit'
            submenu: templateEdit viewstate
        }
        {
            label: i18n.__ 'menu.view.title:View'
            submenu: templateView viewstate
        }
        {
          label: i18n.__ 'menu.help.title:Help'
          submenu: [
            {
              label: i18n.__ 'menu.help.about.title:About YakYak'
              action: {name: 'show-about'}
            }
          ]
        } if !isDarwin
        {
            label: i18n.__ 'menu.window.title:Window'
            submenu: templateWindow viewstate
        } if isDarwin
    ].filter (n) -> n != undefined

module.exports = (viewstate) ->
    # Deprecated in electron >= 7.0.0
    ipc.send 'menu:setapplicationmenu', templateMenu(viewstate)
