remote = require('electron').remote
Menu = remote.Menu

{notificationCenterSupportsSound} = require '../util'

platform = require('os').platform()
# to reduce number of == comparisons
isDarwin = platform == 'darwin'
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
            label: i18n.__ 'menu.help.about.title'
            click: (it) -> action 'show-about'
        } if isDarwin
        #{ type: 'separator' }
        # { label: 'Preferences...', accelerator: 'Command+,',
        # click: => delegate.openConfig() }
        { type: 'separator' } if isDarwin
        {
            label: i18n.__ 'menu.file.hide'
            accelerator: getAccelerator('hideyakyak')
            role: if isDarwin then 'hide' else 'minimize'
        }
        {
            label: i18n.__ 'menu.file.hide_others'
            accelerator: getAccelerator('hideothers')
            role: 'hideothers'
        } if isDarwin
        {
            label: i18n.__ "menu.file.show"
            role: 'unhide'
        } if isDarwin # old show all
        { type: 'separator' }
        {
          label: i18n.__ 'menu.file.inspector'
          accelerator: getAccelerator('openinspector')
          click: -> action 'devtools'
        }
        { type: 'separator' }
        {
            label: i18n.__('menu.file.logout')
            click: -> action 'logout'
            enabled: viewstate.loggedin
        }
        {
            label: i18n.__('menu.file.quit')
            accelerator: getAccelerator('quit')
            click: -> action 'quit'
        }
    ].filter (n) -> n != undefined

templateEdit = (viewstate) ->
    languages = for loc in i18n.getLocales()
        {
            label: i18n.getCatalog(loc).__MyLocaleLanguage__
            type: 'radio'
            checked: viewstate.language == loc
            value: loc
            click: (it) ->
                action 'changelanguage', it.value
        }
    [
        {
            label: i18n.__ 'menu.edit.undo'
            role: 'undo'
        }
        {
            label: i18n.__ 'menu.edit.redo'
            role: 'redo'
        }
        { type: 'separator' }
        {
            label: i18n.__ 'menu.edit.cut'
            role: 'cut'
        }
        {
            label: i18n.__ 'menu.edit.copy'
            role: 'copy'
        }
        {
            label: i18n.__ 'menu.edit.paste'
            role: 'paste'
        }
        {
            label: i18n.__ 'menu.edit.select_all'
            role: 'selectall'
        }
        { type: 'separator' }
        {
            label: i18n.__('menu.edit.language')
            submenu: languages
        }
    ].filter (n) -> n != undefined

templateView = (viewstate) ->
    [
        {
            label: i18n.__('menu.view.conversation.title')
            submenu: [
              {
                  type: 'checkbox'
                  label: i18n.__('menu.view.conversation.thumbnails.show')
                  checked: viewstate.showConvThumbs
                  enabled: viewstate.loggedin
                  click: (it) -> action 'showconvthumbs', it.checked
              }
              {
                  type: 'checkbox'
                  label: i18n.__('menu.view.conversation.thumbnails.only')
                  checked:viewstate.showConvMin
                  enabled: viewstate.loggedin
                  click: (it) -> action 'showconvmin', it.checked
              }
              {
                  type: 'checkbox'
                  label: i18n.__('menu.view.conversation.thumbnails.animated')
                  checked:viewstate.showAnimatedThumbs
                  enabled: viewstate.loggedin
                  click: (it) -> action 'showanimatedthumbs', it.checked
              }
              {
                  type: 'checkbox'
                  label: i18n.__('menu.view.conversation.timestamp')
                  checked:viewstate.showConvTime
                  enabled: viewstate.loggedin && !viewstate.showConvMin
                  click: (it) -> action 'showconvtime', it.checked
              }
              {
                  type: 'checkbox'
                  label: i18n.__('menu.view.conversation.last')
                  checked:viewstate.showConvLast
                  enabled: viewstate.loggedin && !viewstate.showConvMin
                  click: (it) -> action 'showconvlast', it.checked
              }
          ]
        }
        {
            label: i18n.__ 'menu.view.notification.title'
            submenu: [
                {
                    type: 'checkbox'
                    label: i18n.__('menu.view.notification.show')
                    checked: viewstate.showPopUpNotifications
                    enabled: viewstate.loggedin
                    click: (it) -> action 'showpopupnotifications', it.checked
                }, {
                    type: 'checkbox'
                    label: i18n.__('menu.view.notification.message')
                    checked: viewstate.showMessageInNotification
                    enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                    click: (it) -> action 'showmessageinnotification', it.checked
                }, {
                    type: 'checkbox'
                    label: i18n.__('menu.view.notification.username')
                    checked: viewstate.showUsernameInNotification
                    enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                    click: (it) -> action 'showusernameinnotification', it.checked
                }
                {
                  type: 'checkbox'
                  label: i18n.__ (if isDarwin then 'menu.view.notification.avatar' else 'menu.view.notification.icon')
                  enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                  checked: viewstate.showIconNotification
                  click: (it) -> action 'showiconnotification', it.checked
                }
                {
                  type: 'checkbox'
                  label: i18n.__('menu.view.notification.mute')
                  checked: viewstate.muteSoundNotification
                  enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                  click: (it) -> action 'mutesoundnotification', it.checked
                }
                {
                  type: 'checkbox'
                  label: i18n.__('menu.view.notification.custom')
                  checked: viewstate.forceCustomSound
                  enabled: viewstate.loggedin && viewstate.showPopUpNotifications && !viewstate.muteSoundNotification
                  click: (it) -> action 'forcecustomsound', it.checked
                } if notifierSupportsSound
            ].filter (n) -> n != undefined
        }
        {
            type: 'checkbox'
            label: i18n.__('menu.view.emoji')
            checked: viewstate.convertEmoji
            enabled: viewstate.loggedin
            click: (it) -> action 'convertemoji', it.checked
        }
        {
            label: i18n.__('menu.view.color_scheme.title')
            submenu: [
              {
                  label: i18n.__('menu.view.color_scheme.default')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'default'
                  click: -> action 'changetheme', 'default'
              }
              {
                  label: i18n.__('menu.view.color_scheme.blue')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'blue'
                  click: -> action 'changetheme', 'blue'
              }
              {
                  label: i18n.__('menu.view.color_scheme.dark')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'dark'
                  click: -> action 'changetheme', 'dark'
              }
              {
                  label: i18n.__('menu.view.color_scheme.material')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'material'
                  click: -> action 'changetheme', 'material'
              }
            ]
        }
        {
            label: i18n.__('menu.view.font.title')
            submenu: [
              {
                  label: i18n.__('menu.view.font.extra_small')
                  type: 'radio'
                  checked: viewstate.fontSize == 'x-small'
                  click: -> action 'changefontsize', 'x-small'
              }
              {
                  label: i18n.__('menu.view.font.small')
                  type: 'radio'
                  checked: viewstate.fontSize == 'small'
                  click: -> action 'changefontsize', 'small'
              }
              {
                  label: i18n.__('menu.view.font.medium')
                  type: 'radio'
                  checked: viewstate.fontSize == 'medium'
                  click: -> action 'changefontsize', 'medium'
              }
              {
                  label: i18n.__('menu.view.font.large')
                  type: 'radio'
                  checked: viewstate.fontSize == 'large'
                  click: -> action 'changefontsize', 'large'
              }
              {
                  label: i18n.__('menu.view.font.extra_large')
                  type: 'radio'
                  checked: viewstate.fontSize == 'x-large'
                  click: -> action 'changefontsize', 'x-large'
              }
            ]
        }
        {
            label: i18n.__ 'menu.view.fullscreen'
            role: 'togglefullscreen'
        }
        {
            label: i18n.__ 'menu.view.zoom.in'
            # seee https://github.com/atom/electron/issues/1507
            role: 'zoomin'
        }
        {
            label: i18n.__ 'menu.view.zoom.out'
            role: 'zoomout'
        }
        {
            label: i18n.__ 'menu.view.zoom.reset'
            role: 'resetzoom'
        }
        { type: 'separator' }
        {
            label: i18n.__('menu.view.conversation.previous')
            accelerator: getAccelerator('previousconversation')
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', -1
        }
        {
            label: i18n.__('menu.view.conversation.next')
            accelerator: getAccelerator('nextconversation')
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', +1
        }
        {
            label: i18n.__('menu.view.conversation.select')
            enabled: viewstate.loggedin
            submenu: [
              {
                  label: i18n.__('conversation.numbered', 1)
                  accelerator: getAccelerator('conversation1')
                  click: -> action 'selectConvIndex', 0
              }
              {
                  label: i18n.__('conversation.numbered', 2)
                  accelerator: getAccelerator('conversation2')
                  click: -> action 'selectConvIndex', 1
              }
              {
                  label: i18n.__('conversation.numbered', 3)
                  accelerator: getAccelerator('conversation3')
                  click: -> action 'selectConvIndex', 2
              }
              {
                  label: i18n.__('conversation.numbered', 4)
                  accelerator: getAccelerator('conversation4')
                  click: -> action 'selectConvIndex', 3
              }
              {
                  label: i18n.__('conversation.numbered', 5)
                  accelerator: getAccelerator('conversation5')
                  click: -> action 'selectConvIndex', 4
              }
              {
                  label: i18n.__('conversation.numbered', 6)
                  accelerator: getAccelerator('conversation6')
                  click: -> action 'selectConvIndex', 5
              }
              {
                  label: i18n.__('conversation.numbered', 7)
                  accelerator: getAccelerator('conversation7')
                  click: -> action 'selectConvIndex', 6
              }
              {
                  label: i18n.__('conversation.numbered', 8)
                  accelerator: getAccelerator('conversation8')
                  click: -> action 'selectConvIndex', 7
              }
              {
                  label: i18n.__('conversation.numbered', 9)
                  accelerator: getAccelerator('conversation9')
                  click: -> action 'selectConvIndex', 8
              }
            ]
        }
        { type: 'separator' }
        {
            label: i18n.__('menu.view.tray.show_tray')
            type: 'checkbox'
            enabled: not viewstate.hidedockicon
            checked:  viewstate.showtray
            click: -> action 'toggleshowtray'
        }
        {
          label: i18n.__('menu.view.escape.title')
          submenu: [
              {
                  label: i18n.__('menu.view.escape.hide')
                  type: 'radio'
                  enabled: viewstate.showtray
                  checked: viewstate.showtray && !viewstate.escapeClearsInput
                  click: -> action 'setescapeclearsinput', false
              }
              {
                  label: i18n.__('menu.view.escape.clear') + if !viewstate.showtray then " (#{i18n.__ 'menu.view.escape.default'})" else ''
                  type: 'radio'
                  enabled: viewstate.showtray
                  checked: !viewstate.showtray || viewstate.escapeClearsInput
                  click: -> action 'setescapeclearsinput', true
              }
          ]
        }
        {
            label: i18n.__('menu.view.hide_dock')
            type: 'checkbox'
            enabled: viewstate.showtray
            checked:  viewstate.hidedockicon
            click: -> action 'togglehidedockicon'
        } if isDarwin
    ].filter (n) -> n != undefined

templateWindow = (viewstate) -> [
    {
        label: i18n.__ 'menu.window.minimize'
        role: 'minimize'
    }
    {
        label: i18n.__('menu.window.close')
        accelerator: getAccelerator('close')
        role: 'close'
    }
    { type: 'separator' }
    {
        label: i18n.__('menu.window.front')
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
            label: i18n.__ 'menu.file.title'
            submenu: templateYakYak viewstate
        }
        {
            label: i18n.__ 'menu.edit.title'
            submenu: templateEdit viewstate
        }
        {
            label: i18n.__ 'menu.view.title'
            submenu: templateView viewstate
        }
        {
          label: i18n.__ 'menu.help.title'
          submenu: [
            {
              label: i18n.__ 'menu.help.about.title'
              click: () -> action 'show-about'
            }
          ]
        } if !isDarwin
        {
            label: i18n.__ 'menu.window.title'
            submenu: templateWindow viewstate
        } if isDarwin
    ].filter (n) -> n != undefined

module.exports = (viewstate) ->
    Menu.setApplicationMenu Menu.buildFromTemplate templateMenu(viewstate)
