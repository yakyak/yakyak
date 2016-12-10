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
            label: i18n.__('About YakYak')
            click: (it) -> action 'show-about'
        } if isDarwin
        #{ type: 'separator' }
        # { label: 'Preferences...', accelerator: 'Command+,',
        # click: => delegate.openConfig() }
        { type: 'separator' } if isDarwin
        {
            label: i18n.__('Hide YakYak')
            accelerator: getAccelerator('hideyakyak')
            role: if isDarwin then 'hide' else 'minimize'
        }
        {
            label: i18n.__('Hide Others')
            accelerator: getAccelerator('hideothers')
            role: 'hideothers'
        } if isDarwin
        {
            label: i18n.__ "Show All"
            role: 'unhide'
        } if isDarwin # old show all
        { type: 'separator' }
        {
          label: i18n.__('Open Inspector')
          accelerator: getAccelerator('openinspector')
          click: -> action 'devtools'
        }
        { type: 'separator' }
        {
            label: i18n.__('Logout')
            click: -> action 'logout'
            enabled: viewstate.loggedin
        }
        {
            label: i18n.__('Quit')
            accelerator: getAccelerator('quit')
            click: -> action 'quit'
        }
    ].filter (n) -> n != undefined

templateEdit = (viewstate) ->
    [
        {
            label: i18n.__ 'Undo'
            role: 'undo'
        }
        {
            label: i18n.__ 'Redo'
            role: 'redo'
        }
        { type: 'separator' }
        {
            label: i18n.__ 'Cut'
            role: 'cut'
        }
        {
            label: i18n.__ 'Copy'
            role: 'copy'
        }
        {
            label: i18n.__ 'Paste'
            role: 'paste'
        }
        {
            label: i18n.__ 'Select All'
            role: 'selectall'
        }
    ].filter (n) -> n != undefined

templateView = (viewstate) ->
    [
        {
            label: i18n.__('Conversation List')
            submenu: [
              {
                  type: 'checkbox'
                  label: i18n.__('Show Thumbnails')
                  checked: viewstate.showConvThumbs
                  enabled: viewstate.loggedin
                  click: (it) -> action 'showconvthumbs', it.checked
              }
              {
                  type: 'checkbox'
                  label: i18n.__('Show Thumbnails Only')
                  checked:viewstate.showConvMin
                  enabled: viewstate.loggedin
                  click: (it) -> action 'showconvmin', it.checked
              }
              {
                  type: 'checkbox'
                  label: i18n.__('Show Animated Thumbnails')
                  checked:viewstate.showAnimatedThumbs
                  enabled: viewstate.loggedin
                  click: (it) -> action 'showanimatedthumbs', it.checked
              }
              {
                  type: 'checkbox'
                  label: i18n.__('Show Conversation Timestamp')
                  checked:viewstate.showConvTime
                  enabled: viewstate.loggedin && !viewstate.showConvMin
                  click: (it) -> action 'showconvtime', it.checked
              }
              {
                  type: 'checkbox'
                  label: i18n.__('Show Conversation Last Message')
                  checked:viewstate.showConvLast
                  enabled: viewstate.loggedin && !viewstate.showConvMin
                  click: (it) -> action 'showconvlast', it.checked
              }
          ]
        }
        {
            label: i18n.__ 'Pop-Up Notification'
            submenu: [
                {
                    type: 'checkbox'
                    label: i18n.__('Show notifications')
                    checked: viewstate.showPopUpNotifications
                    enabled: viewstate.loggedin
                    click: (it) -> action 'showpopupnotifications', it.checked
                }, {
                    type: 'checkbox'
                    label: i18n.__('Show message in notifications')
                    checked: viewstate.showMessageInNotification
                    enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                    click: (it) -> action 'showmessageinnotification', it.checked
                }, {
                    type: 'checkbox'
                    label: i18n.__('Show username in notifications')
                    checked: viewstate.showUsernameInNotification
                    enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                    click: (it) -> action 'showusernameinnotification', it.checked
                }
                {
                  type: 'checkbox'
                  label: i18n.__ ("Show #{if isDarwin then 'user avatar' else 'YakYak'} icon in notifications")
                  enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                  checked: viewstate.showIconNotification
                  click: (it) -> action 'showiconnotification', it.checked
                }
                {
                  type: 'checkbox'
                  label: i18n.__('Disable sound in notifications')
                  checked: viewstate.muteSoundNotification
                  enabled: viewstate.loggedin && viewstate.showPopUpNotifications
                  click: (it) -> action 'mutesoundnotification', it.checked
                }
                {
                  type: 'checkbox'
                  label: i18n.__('Use YakYak custom sound for notifications')
                  checked: viewstate.forceCustomSound
                  enabled: viewstate.loggedin && viewstate.showPopUpNotifications && !viewstate.muteSoundNotification
                  click: (it) -> action 'forcecustomsound', it.checked
                } if notifierSupportsSound
            ].filter (n) -> n != undefined
        }
        {
            type: 'checkbox'
            label: i18n.__('Convert text to emoji')
            checked: viewstate.convertEmoji
            enabled: viewstate.loggedin
            click: (it) -> action 'convertemoji', it.checked
        }
        {
            label: i18n.__('Color Scheme')
            submenu: [
              {
                  label: i18n.__('Default')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'default'
                  click: -> action 'changetheme', 'default'
              }
              {
                  label: i18n.__('Blue')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'blue'
                  click: -> action 'changetheme', 'blue'
              }
              {
                  label: i18n.__('Dark')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'dark'
                  click: -> action 'changetheme', 'dark'
              }
              {
                  label: i18n.__('Material')
                  type: 'radio'
                  checked: viewstate.colorScheme == 'material'
                  click: -> action 'changetheme', 'material'
              }
            ]
        }
        {
            label: i18n.__('Font Size')
            submenu: [
              {
                  label: i18n.__('Extra Small')
                  type: 'radio'
                  checked: viewstate.fontSize == 'x-small'
                  click: -> action 'changefontsize', 'x-small'
              }
              {
                  label: i18n.__('Small')
                  type: 'radio'
                  checked: viewstate.fontSize == 'small'
                  click: -> action 'changefontsize', 'small'
              }
              {
                  label: i18n.__('Medium')
                  type: 'radio'
                  checked: viewstate.fontSize == 'medium'
                  click: -> action 'changefontsize', 'medium'
              }
              {
                  label: i18n.__('Large')
                  type: 'radio'
                  checked: viewstate.fontSize == 'large'
                  click: -> action 'changefontsize', 'large'
              }
              {
                  label: i18n.__('Extra Large')
                  type: 'radio'
                  checked: viewstate.fontSize == 'x-large'
                  click: -> action 'changefontsize', 'x-large'
              }
            ]
        }
        {
            label: i18n.__ 'Toggle Fullscreen'
            role: 'togglefullscreen'
        }
        {
            label: i18n.__ 'Zoom in'
            # seee https://github.com/atom/electron/issues/1507
            role: 'zoomin'
        }
        {
            label: i18n.__ 'Zoom out'
            role: 'zoomout'
        }
        {
            label: i18n.__ 'Actual size'
            role: 'resetzoom'
        }
        { type: 'separator' }
        {
            label: i18n.__('Previous Conversation')
            accelerator: getAccelerator('previousconversation')
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', -1
        }
        {
            label: i18n.__('Next Conversation')
            accelerator: getAccelerator('nextconversation')
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', +1
        }
        {
            label: i18n.__('Select Conversation')
            enabled: viewstate.loggedin
            submenu: [
              {
                  label: i18n.__('Conversation 1')
                  accelerator: getAccelerator('conversation1')
                  click: -> action 'selectConvIndex', 0
              }
              {
                  label: i18n.__('Conversation 2')
                  accelerator: getAccelerator('conversation2')
                  click: -> action 'selectConvIndex', 1
              }
              {
                  label: i18n.__('Conversation 3')
                  accelerator: getAccelerator('conversation3')
                  click: -> action 'selectConvIndex', 2
              }
              {
                  label: i18n.__('Conversation 4')
                  accelerator: getAccelerator('conversation4')
                  click: -> action 'selectConvIndex', 3
              }
              {
                  label: i18n.__('Conversation 5')
                  accelerator: getAccelerator('conversation5')
                  click: -> action 'selectConvIndex', 4
              }
              {
                  label: i18n.__('Conversation 6')
                  accelerator: getAccelerator('conversation6')
                  click: -> action 'selectConvIndex', 5
              }
              {
                  label: i18n.__('Conversation 7')
                  accelerator: getAccelerator('conversation7')
                  click: -> action 'selectConvIndex', 6
              }
              {
                  label: i18n.__('Conversation 8')
                  accelerator: getAccelerator('conversation8')
                  click: -> action 'selectConvIndex', 7
              }
              {
                  label: i18n.__('Conversation 9')
                  accelerator: getAccelerator('conversation9')
                  click: -> action 'selectConvIndex', 8
              }
            ]
        }
        { type: 'separator' }
        {
            label: i18n.__('Show tray icon')
            type: 'checkbox'
            enabled: not viewstate.hidedockicon
            checked:  viewstate.showtray
            click: -> action 'toggleshowtray'
        }
        {
          label: i18n.__('Escape key behavior')
          submenu: [
              {
                  label: i18n.__('Hides window')
                  type: 'radio'
                  enabled: viewstate.showtray
                  checked: viewstate.showtray && !viewstate.escapeClearsInput
                  click: -> action 'setescapeclearsinput', false
              }
              {
                  label: i18n.__('Clears input') + if !viewstate.showtray then " (#{i18n.__ 'default when tray is not showing'})" else ''
                  type: 'radio'
                  enabled: viewstate.showtray
                  checked: !viewstate.showtray || viewstate.escapeClearsInput
                  click: -> action 'setescapeclearsinput', true
              }
          ]
        }
        {
            label: i18n.__('Hide Dock icon')
            type: 'checkbox'
            enabled: viewstate.showtray
            checked:  viewstate.hidedockicon
            click: -> action 'togglehidedockicon'
        } if isDarwin
    ].filter (n) -> n != undefined

templateWindow = (viewstate) -> [
    {
        label: i18n.__ 'Minimize'
        role: 'minimize'
    }
    {
        label: i18n.__('Close')
        accelerator: getAccelerator('close')
        role: 'close'
    }
    { type: 'separator' }
    {
        label: i18n.__('Bring All to Front')
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
            label: i18n.__('YakYak')
            submenu: templateYakYak viewstate
        }
        {
            label: i18n.__('Edit')
            submenu: templateEdit viewstate
        }
        {
            label: i18n.__('View')
            submenu: templateView viewstate
        }
        {
          label: i18n.__ 'Help'
          submenu: [
            {
              label: i18n.__('About')
              click: () -> action 'show-about'
            }
          ]
        } if !isDarwin
        {
            label: i18n.__('Window')
            submenu: templateWindow viewstate
        } if isDarwin
    ].filter (n) -> n != undefined

module.exports = (viewstate) ->
    Menu.setApplicationMenu Menu.buildFromTemplate templateMenu(viewstate)
