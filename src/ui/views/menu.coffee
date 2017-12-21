remote = require('electron').remote
Menu = remote.Menu

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
    # Platform specific
    previousconversation: { default: 'Ctrl+K', darwin:'Command+Shift+Tab' }
    nextconversation:  { default: 'Control+J', darwin:'Command+Tab' }
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
            click: (it) -> action 'show-about'
        } if isDarwin
        {
            type: 'checkbox'
            label: i18n.__('menu.help.about.startup:Open on Startup')
            checked: viewstate.openOnSystemStartup
            click: (it) -> action 'openonsystemstartup', it.checked
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
          click: -> action 'devtools'
        }
        {
            type: 'checkbox'
            label: i18n.__('menu.file.google:Google Voice Mode')
            checked: viewstate.googleVoiceMode
            enabled: viewstate.loggedin
            click: (it) -> action 'enablegooglevoicemode', it.checked
        }
        { type: 'separator' }
        {
            label: i18n.__('menu.file.logout:Logout')
            click: -> action 'logout'
            enabled: viewstate.loggedin
        }
        {
            label: i18n.__('menu.file.quit:Quit')
            accelerator: getAccelerator('quit')
            click: -> action 'quit'
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
            click: (it) ->
                action 'changelanguage', it.value
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
            click: (it) -> action 'setusesystemdateformat', it.checked
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
                  click: (it) -> action 'showconvthumbs', it.checked
              }
              {
                  type: 'checkbox'
                  label: i18n.__('menu.view.conversation.thumbnails.only:Show Thumbnails Only')
                  checked:viewstate.showConvMin
                  enabled: viewstate.loggedin
                  click: (it) -> action 'showconvmin', it.checked
              }
              {
                  type: 'checkbox'
                  label: i18n.__('menu.view.conversation.thumbnails.animated:Show Animated Thumbnails')
                  checked:viewstate.showAnimatedThumbs
                  enabled: viewstate.loggedin
                  click: (it) -> action 'showanimatedthumbs', it.checked
              }
              {
                  type: 'checkbox'
                  label: i18n.__('menu.view.conversation.timestamp:Show Conversation Timestamp')
                  checked:viewstate.showConvTime
                  enabled: viewstate.loggedin && !viewstate.showConvMin
                  click: (it) -> action 'showconvtime', it.checked
              }
              {
                  type: 'checkbox'
                  label: i18n.__('menu.view.conversation.last:Show Conversation Last Message')
                  checked:viewstate.showConvLast
                  enabled: viewstate.loggedin && !viewstate.showConvMin
                  click: (it) -> action 'showconvlast', it.checked
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
                    click: (it) -> action 'showpopupnotifications', it.checked
                }, {
                    type: 'checkbox'
                    label: i18n.__('menu.view.notification.message:Show message in notifications')
                    checked: viewstate.showMessageInNotification
                    enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                    click: (it) -> action 'showmessageinnotification', it.checked
                }, {
                    type: 'checkbox'
                    label: i18n.__('menu.view.notification.username:Show username in notifications')
                    checked: viewstate.showUsernameInNotification
                    enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                    click: (it) -> action 'showusernameinnotification', it.checked
                }
                {
                  type: 'checkbox'
                  label: i18n.__ (if isDarwin then 'menu.view.notification.avatar:Show user avatar icon in notifications' else 'menu.view.notification.icon:Show YakYak icon in notifications')
                  enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                  checked: viewstate.showIconNotification
                  click: (it) -> action 'showiconnotification', it.checked
                }
                {
                  type: 'checkbox'
                  label: i18n.__('menu.view.notification.mute:Disable sound in notifications')
                  checked: viewstate.muteSoundNotification
                  enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                  click: (it) -> action 'mutesoundnotification', it.checked
                }
                {
                  type: 'checkbox'
                  label: i18n.__('menu.view.notification.custom_sound:Use YakYak custom sound for notifications')
                  checked: viewstate.forceCustomSound
                  enabled: viewstate.loggedin && viewstate.showPopUpNotifications && !viewstate.muteSoundNotification
                  click: (it) -> action 'forcecustomsound', it.checked
                } if notifierSupportsSound
            ].filter (n) -> n != undefined
        }
        {
            type: 'checkbox'
            label: i18n.__('menu.view.emoji:Convert text to emoji')
            checked: viewstate.convertEmoji
            enabled: viewstate.loggedin
            click: (it) -> action 'convertemoji', it.checked
        }
        {
            type: 'checkbox'
            label: i18n.__('menu.view.suggestemoji:Suggest emoji on typing')
            checked: viewstate.suggestEmoji
            enabled: viewstate.loggedin
            click: (it) -> action 'suggestemoji', it.checked
        }
        {
            label: i18n.__('menu.view.color_scheme.title:Color Scheme')
            submenu: [
              {
                  label: i18n.__('menu.view.color_scheme.default:Original')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'default'
                  click: -> action 'changetheme', 'default'
              }
              {
                  label: i18n.__('menu.view.color_scheme.blue:Blue')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'blue'
                  click: -> action 'changetheme', 'blue'
              }
              {
                  label: i18n.__('menu.view.color_scheme.dark:Dark')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'dark'
                  click: -> action 'changetheme', 'dark'
              }
              {
                  label: i18n.__('menu.view.color_scheme.material:Material')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'material'
                  click: -> action 'changetheme', 'material'
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
                  click: -> action 'changefontsize', 'x-small'
              }
              {
                  label: i18n.__('menu.view.font.small:Small')
                  type: 'radio'
                  checked: viewstate.fontSize == 'small'
                  click: -> action 'changefontsize', 'small'
              }
              {
                  label: i18n.__('menu.view.font.medium:Medium')
                  type: 'radio'
                  checked: viewstate.fontSize == 'medium'
                  click: -> action 'changefontsize', 'medium'
              }
              {
                  label: i18n.__('menu.view.font.large:Large')
                  type: 'radio'
                  checked: viewstate.fontSize == 'large'
                  click: -> action 'changefontsize', 'large'
              }
              {
                  label: i18n.__('menu.view.font.extra_large:Extra Large')
                  type: 'radio'
                  checked: viewstate.fontSize == 'x-large'
                  click: -> action 'changefontsize', 'x-large'
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
            label: i18n.__('menu.view.conversation.previous:Previous Conversation')
            accelerator: getAccelerator('previousconversation')
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', -1
        }
        {
            label: i18n.__('menu.view.conversation.next:Next Conversation')
            accelerator: getAccelerator('nextconversation')
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', +1
        }
        {
            label: i18n.__('menu.view.conversation.select:Select Conversation')
            enabled: viewstate.loggedin
            submenu: [
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 1)
                  accelerator: getAccelerator('conversation1')
                  click: -> action 'selectConvIndex', 0
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 2)
                  accelerator: getAccelerator('conversation2')
                  click: -> action 'selectConvIndex', 1
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 3)
                  accelerator: getAccelerator('conversation3')
                  click: -> action 'selectConvIndex', 2
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 4)
                  accelerator: getAccelerator('conversation4')
                  click: -> action 'selectConvIndex', 3
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 5)
                  accelerator: getAccelerator('conversation5')
                  click: -> action 'selectConvIndex', 4
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 6)
                  accelerator: getAccelerator('conversation6')
                  click: -> action 'selectConvIndex', 5
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 7)
                  accelerator: getAccelerator('conversation7')
                  click: -> action 'selectConvIndex', 6
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 8)
                  accelerator: getAccelerator('conversation8')
                  click: -> action 'selectConvIndex', 7
              }
              {
                  label: i18n.__('conversation.numbered:Conversation %d', 9)
                  accelerator: getAccelerator('conversation9')
                  click: -> action 'selectConvIndex', 8
              }
            ]
        }
        { type: 'separator' }
        {
            label: i18n.__('menu.view.tray.show_tray:Show tray icon')
            type: 'checkbox'
            enabled: not viewstate.hidedockicon
            checked:  viewstate.showtray
            click: -> action 'toggleshowtray'
        }
        {
          label: i18n.__('menu.view.escape.title:Escape key behavior')
          submenu: [
              {
                  label: i18n.__('menu.view.escape.hide:Hides window')
                  type: 'radio'
                  enabled: viewstate.showtray
                  checked: viewstate.showtray && !viewstate.escapeClearsInput
                  click: -> action 'setescapeclearsinput', false
              }
              {
                  label: i18n.__('menu.view.escape.clear:Clears input') + if !viewstate.showtray then " (#{i18n.__ 'menu.view.escape.default:default when tray is not showing'})" else ''
                  type: 'radio'
                  enabled: viewstate.showtray
                  checked: !viewstate.showtray || viewstate.escapeClearsInput
                  click: -> action 'setescapeclearsinput', true
              }
          ]
        }
        {
            label: i18n.__('menu.view.hide_dock:Hide Dock icon')
            type: 'checkbox'
            enabled: viewstate.showtray
            checked:  viewstate.hidedockicon
            click: -> action 'togglehidedockicon'
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
              click: () -> action 'show-about'
            }
          ]
        } if !isDarwin
        {
            label: i18n.__ 'menu.window.title:Window'
            submenu: templateWindow viewstate
        } if isDarwin
    ].filter (n) -> n != undefined

module.exports = (viewstate) ->
    Menu.setApplicationMenu Menu.buildFromTemplate templateMenu(viewstate)
