remote = require('electron').remote
Menu = remote.Menu

platform = require('os').platform()
# to reduce number of == comparisons
isDarwin = platform == 'darwin'
isNotDarwin = platform != 'darwin'

acceleratorMap = {
    # MacOSX specific
    hideyakyak: { default: 'CmdOrCtrl+H' }
    hideothers: { default: '', darwin:'Command+Shift+H' }
    showall: { default: '', darwin:'' }
    openinspector: { default: 'CmdOrCtrl+Alt+I' }
    close: { default: '', darwin:'Command+W' }
    # Common shortcuts
    quit: { default: 'CmdOrCtrl+Q' }
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
    if (retVal = acceleratorMap[key][platform])?
        retVal
    else
        acceleratorMap[key]['default']

templateYakYak = (viewstate) ->

    [
        { label: 'About YakYak', role: 'about' } if isDarwin
        #{ type: 'separator' }
        # { label: 'Preferences...', accelerator: 'Command+,',
        # click: => delegate.openConfig() }
        { type: 'separator' } if isDarwin
        {
            label: 'Hide YakYak'
            accelerator: getAccelerator('hideyakyak')
            role: if isDarwin then 'hide' else 'minimize'
        }
        {
            label: 'Hide Others'
            accelerator: getAccelerator('hideothers')
            role: 'hideothers'
        } if isDarwin
        { role: 'unhide' } if isDarwin # old show all
        { type: 'separator' }
        {
          label: 'Open Inspector'
          accelerator: getAccelerator('openinspector')
          click: -> action 'devtools'
        }
        { type: 'separator' }
        {
            label: 'Logout',
            click: -> action 'logout'
            enabled: viewstate.loggedin
        }
        {
            label: 'Quit'
            accelerator: getAccelerator('quit')
            click: -> action 'quit'
        }
    ].filter (n) -> n != undefined

templateEdit = (viewstate) ->
    [
        { role: 'undo' }
        { role: 'redo' }
        { type: 'separator' }
        { role: 'cut' }
        { role: 'copy' }
        { role: 'paste' }
        { role: 'selectall' }
    ].filter (n) -> n != undefined

templateView = (viewstate) ->
    [
        {
            label: 'Conversation List'
            submenu: [
              {
                  type: 'checkbox'
                  label: 'Show Thumbnails'
                  checked: viewstate.showConvThumbs
                  enabled: viewstate.loggedin
                  click: (it) -> action 'showconvthumbs', it.checked
              }
              {
                  type: 'checkbox'
                  label: 'Show Thumbnails Only'
                  checked:viewstate.showConvMin
                  enabled: viewstate.loggedin
                  click: (it) -> action 'showconvmin', it.checked
              }
              {
                  type: 'checkbox'
                  label: 'Show Animated Thumbnails'
                  checked:viewstate.showAnimatedThumbs
                  enabled: viewstate.loggedin
                  click: (it) -> action 'showanimatedthumbs', it.checked
              }
              {
                  type: 'checkbox'
                  label: 'Show Conversation Timestamp'
                  checked:viewstate.showConvTime
                  enabled: viewstate.loggedin && !viewstate.showConvMin
                  click: (it) -> action 'showconvtime', it.checked
              }
              {
                  type: 'checkbox'
                  label: 'Show Conversation Last Message'
                  checked:viewstate.showConvLast
                  enabled: viewstate.loggedin && !viewstate.showConvMin
                  click: (it) -> action 'showconvlast', it.checked
              }
          ]
        }
        {
            type: 'checkbox'
            label: 'Show Pop-Up (Toast) Notifications'
            checked: viewstate.showPopUpNotifications
            enabled: viewstate.loggedin
            click: (it) -> action 'showpopupnotifications', it.checked
        }
        {
            type: 'checkbox'
            label: 'Convert text to emoji'
            checked: viewstate.convertEmoji
            enabled: viewstate.loggedin
            click: (it) -> action 'convertemoji', it.checked
        }
        {
            label: 'Color Scheme'
            submenu: [
              {
                  label: 'Default'
                  type: 'radio'
                  checked: viewstate.colorScheme == 'default'
                  click: -> action 'changetheme', 'default'
              }
              {
                  label: 'Blue'
                  type: 'radio'
                  checked: viewstate.colorScheme == 'blue'
                  click: -> action 'changetheme', 'blue'
              }
              {
                  label: 'Dark'
                  type: 'radio'
                  checked: viewstate.colorScheme == 'dark'
                  click: -> action 'changetheme', 'dark'
              }
              {
                  label: 'Material'
                  type: 'radio'
                  checked: viewstate.colorScheme == 'material'
                  click: -> action 'changetheme', 'material'
              }
            ]
        }
        {
            label: 'Font Size'
            submenu: [
              {
                  label: 'Extra Small'
                  type: 'radio'
                  checked: viewstate.fontSize == 'x-small'
                  click: -> action 'changefontsize', 'x-small'
              }
              {
                  label: 'Small'
                  type: 'radio'
                  checked: viewstate.fontSize == 'small'
                  click: -> action 'changefontsize', 'small'
              }
              {
                  label: 'Medium'
                  type: 'radio'
                  checked: viewstate.fontSize == 'medium'
                  click: -> action 'changefontsize', 'medium'
              }
              {
                  label: 'Large'
                  type: 'radio'
                  checked: viewstate.fontSize == 'large'
                  click: -> action 'changefontsize', 'large'
              }
              {
                  label: 'Extra Large'
                  type: 'radio'
                  checked: viewstate.fontSize == 'x-large'
                  click: -> action 'changefontsize', 'x-large'
              }
            ]
        }
        { role: 'togglefullscreen' }
        { role: 'zoomin' }
        { role: 'zoomout' }
        { role: 'resetzoom' }
        { type: 'separator' }
        {
            label: 'Previous Conversation',
            accelerator: getAccelerator('previousconversation')
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', -1
        }
        {
            label: 'Next Conversation',
            accelerator: getAccelerator('nextconversation')
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', +1
        }
        {
            label: 'Select Conversation',
            enabled: viewstate.loggedin
            submenu: [
              {
                  label: 'Conversation 1'
                  accelerator: getAccelerator('conversation1')
                  click: -> action 'selectConvIndex', 0
              }
              {
                  label: 'Conversation 2'
                  accelerator: getAccelerator('conversation2')
                  click: -> action 'selectConvIndex', 1
              }
              {
                  label: 'Conversation 3'
                  accelerator: getAccelerator('conversation3')
                  click: -> action 'selectConvIndex', 2
              }
              {
                  label: 'Conversation 4'
                  accelerator: getAccelerator('conversation4')
                  click: -> action 'selectConvIndex', 3
              }
              {
                  label: 'Conversation 5'
                  accelerator: getAccelerator('conversation5')
                  click: -> action 'selectConvIndex', 4
              }
              {
                  label: 'Conversation 6'
                  accelerator: getAccelerator('conversation6')
                  click: -> action 'selectConvIndex', 5
              }
              {
                  label: 'Conversation 7'
                  accelerator: getAccelerator('conversation7')
                  click: -> action 'selectConvIndex', 6
              }
              {
                  label: 'Conversation 8'
                  accelerator: getAccelerator('conversation8')
                  click: -> action 'selectConvIndex', 7
              }
              {
                  label: 'Conversation 9'
                  accelerator: getAccelerator('conversation9')
                  click: -> action 'selectConvIndex', 8
              }
            ]
        }
        { type: 'separator' }
        {
            label: 'Show tray icon'
            type: 'checkbox'
            enabled: not viewstate.hidedockicon
            checked:  viewstate.showtray
            click: -> action 'toggleshowtray'
        }
        {
            label: 'Hide Dock icon'
            type: 'checkbox'
            enabled: viewstate.showtray
            checked:  viewstate.hidedockicon
            click: -> action 'togglehidedockicon'
        } if isDarwin
    ].filter (n) -> n != undefined

templateWindow = (viewstate) -> [
    { role: 'minimize' }
    {
        label: 'Close'
        accelerator: getAccelerator('close')
        role: 'close'
    }
    { type: 'separator' }
    {
        label: 'Bring All to Front'
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
            label: 'YakYak'
            submenu: templateYakYak viewstate
        }
        {
            label: 'Edit'
            submenu: templateEdit viewstate
        }
        {
            label: 'View'
            submenu: templateView viewstate
        }
        {
            label: 'Window'
            submenu: templateWindow viewstate
        } if isDarwin
    ].filter (n) -> n != undefined

module.exports = (viewstate) ->
    Menu.setApplicationMenu Menu.buildFromTemplate templateMenu(viewstate)
