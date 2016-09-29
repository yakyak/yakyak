remote = require('electron').remote
Menu = remote.Menu

platform = require('os').platform()
# to reduce number of == comparisons
isDarwin = platform == 'darwin'
isNotDarwin = platform != 'darwin'

acceleratorMap = {
    hideyakyak: {default: 'Control+H', darwin:'Command+H'}
    hideothers: {default: '', darwin:'Command+Shift+H'}
    showall: {default: '', darwin:''}
    openinspector: {default: 'Control+Alt+I', darwin:'Command+Alt+I'}
    quit: {default: 'Control+Q', darwin:'Command+Q'}
    undo: {default: 'Control+Z', darwin:'Command+Z'}
    redo: {default: 'Control+Shift+Z', darwin:'Command+Shift+Z'}
    cut: {default: '', darwin:'Command+X'}
    copy: {default: '', darwin:'Command+C'}
    paste: {default: '', darwin:'Command+V'}
    selectall: {default: '', darwin:'Command+A'}
    togglefullscreen: {default: 'Control+Alt+F', darwin:'Command+Control+F'}
    zoomin: {default: 'Control+Plus', darwin:'Command+Plus'}
    zoomout: {default: 'Control+-', darwin:'Command+-'}
    resetzoom: {default: 'Control+0', darwin:'Command+0'}
    previousconversation: {default: 'Control+K', darwin:'Command+Shift+Tab'}
    nextconversation:  {default: 'Control+J', darwin:'Command+Tab'}
    conversation1: {default: 'Alt+1', darwin:'Command+1'}
    conversation2: {default: 'Alt+2', darwin:'Command+2'}
    conversation3: {default: 'Alt+3', darwin:'Command+3'}
    conversation4: {default: 'Alt+4', darwin:'Command+4'}
    conversation5: {default: 'Alt+5', darwin:'Command+5'}
    conversation6: {default: 'Alt+6', darwin:'Command+6'}
    conversation7: {default: 'Alt+7', darwin:'Command+7'}
    conversation8: {default: 'Alt+8', darwin:'Command+8'}
    conversation9: {default: 'Alt+9', darwin:'Command+9'}
    minimize: {default: '', darwin:'Command+M'}
    close: {default: '', darwin:'Command+W'}
}

getAccelerator = (key) ->
    if (retVal = acceleratorMap[key][platform])?
        retVal
    else
        acceleratorMap[key]['default']

templateYakYak = (viewstate) ->

    [
        { label: 'About YakYak', selector: 'orderFrontStandardAboutPanel:' } if isDarwin
        #{ type: 'separator' }
        # { label: 'Preferences...', accelerator: 'Command+,',
        # click: => delegate.openConfig() }
        { type: 'separator' } if isDarwin
        {
            label: 'Hide YakYak'
            accelerator: getAccelerator('hideyakyak')
            selector: 'hide:' if isDarwin
            role: 'minimize' if isNotDarwin
        }
        if isDarwin
            {
                label: 'Hide Others'
                accelerator: getAccelerator('hideother')
                selector: 'hideOtherApplications:' if isDarwin
            }

            {
                label: 'Show All'
                selector: 'unhideAllApplications:' if isDarwin
            }
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
        {
          label: 'Undo'
          accelerator: getAccelerator('undo')
          selector: 'undo:' if isDarwin
          role: 'undo' if isNotDarwin
        }
        {
          label: 'Redo'
          accelerator: getAccelerator('redo')
          selector: 'redo:' if isDarwin
          role: 'redo' if isNotDarwin
        }
        if isDarwin
            { type: 'separator' }
            {
              label: 'Cut'
              accelerator: getAccelerator('cut')
              selector: 'cut:' if isDarwin
              role: 'cut' if isNotDarwin
            }
            {
              label: 'Copy'
              accelerator: getAccelerator('copy')
              selector: 'copy:' if isDarwin
              role: 'copy' if isNotDarwin
            }
            {
              label: 'Paste'
              accelerator: getAccelerator('paste')
              selector: 'paste:' if isDarwin
              role: 'paste' if isNotDarwin
            }
            {
              label: 'Select All'
              accelerator: getAccelerator('selectall')
              selector: 'selectAll:' if isDarwin
              role: 'selectall' if isNotDarwin
            }
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
              }, {
                  type: 'checkbox'
                  label: 'Show Thumbnails Only'
                  checked:viewstate.showConvMin
                  enabled: viewstate.loggedin
                  click: (it) -> action 'showconvmin', it.checked
              }, {
                  type: 'checkbox'
                  label: 'Show Animated Thumbnails'
                  checked:viewstate.showAnimatedThumbs
                  enabled: viewstate.loggedin
                  click: (it) -> action 'showanimatedthumbs', it.checked
              }, {
                  type: 'checkbox'
                  label: 'Show Conversation Timestamp'
                  checked:viewstate.showConvTime
                  enabled: viewstate.loggedin && !viewstate.showConvMin
                  click: (it) -> action 'showconvtime', it.checked
              }, {
                  type: 'checkbox'
                  label: 'Show Conversation Last Message'
                  checked:viewstate.showConvLast
                  enabled: viewstate.loggedin && !viewstate.showConvMin
                  click: (it) -> action 'showconvlast', it.checked
              }
          ]
        }, {
            type: 'checkbox'
            label: 'Show Pop-Up (Toast) Notifications'
            checked: viewstate.showPopUpNotifications
            enabled: viewstate.loggedin
            click: (it) -> action 'showpopupnotifications', it.checked
        }, {
            type: 'checkbox'
            label: 'Convert text to emoji'
            checked: viewstate.convertEmoji
            enabled: viewstate.loggedin
            click: (it) -> action 'convertemoji', it.checked
        }, {
            label: 'Color Scheme'
            submenu: [
              {
                  label: 'Default'
                  type: 'radio'
                  checked: viewstate.colorScheme == 'default'
                  click: -> action 'changetheme', 'default'
              }, {
                  label: 'Blue'
                  type: 'radio'
                  checked: viewstate.colorScheme == 'blue'
                  click: -> action 'changetheme', 'blue'
              }, {
                  label: 'Dark'
                  type: 'radio'
                  checked: viewstate.colorScheme == 'dark'
                  click: -> action 'changetheme', 'dark'
              }, {
                  label: 'Material'
                  type: 'radio'
                  checked: viewstate.colorScheme == 'material'
                  click: -> action 'changetheme', 'material'
              }
            ]
        }, {
            label: 'Font Size'
            submenu: [
              {
                  label: 'Extra Small'
                  type: 'radio'
                  checked: viewstate.fontSize == 'x-small'
                  click: -> action 'changefontsize', 'x-small'
              }, {
                  label: 'Small'
                  type: 'radio'
                  checked: viewstate.fontSize == 'small'
                  click: -> action 'changefontsize', 'small'
              }, {
                  label: 'Medium'
                  type: 'radio'
                  checked: viewstate.fontSize == 'medium'
                  click: -> action 'changefontsize', 'medium'
              }, {
                  label: 'Large'
                  type: 'radio'
                  checked: viewstate.fontSize == 'large'
                  click: -> action 'changefontsize', 'large'
              }, {
                  label: 'Extra Large'
                  type: 'radio'
                  checked: viewstate.fontSize == 'x-large'
                  click: -> action 'changefontsize', 'x-large'
              }
            ]
        }, {
            label: 'Toggle Full Screen',
            accelerator: getAccelerator('togglefullscreen'),
            click: -> action 'togglefullscreen'
        }, {
            # seee https://github.com/atom/electron/issues/1507
            label: 'Zoom In',
            accelerator: getAccelerator('zoomin'),
            click: -> action 'zoom', +0.25
        }, {
            label: 'Zoom Out',
            accelerator: getAccelerator('zoomout'),
            click: -> action 'zoom', -0.25
        }, {
            label: 'Reset Zoom',
            accelerator: getAccelerator('resetzoom'),
            click: -> action 'zoom'
        }, {
            type: 'separator'
        }, {
            label: 'Previous Conversation',
            accelerator: getAccelerator('previousconversation')
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', -1
        }, {
            label: 'Next Conversation',
            accelerator: getAccelerator('nextconversation')
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', +1
        }, {
            label: 'Select Conversation',
            enabled: viewstate.loggedin
            submenu: [
              {
                  label: 'Conversation 1'
                  accelerator: getAccelarator('conversation1')
                  click: -> action 'selectConvIndex', 0
              }, {
                  label: 'Conversation 2'
                  accelerator: getAccelarator('conversation2')
                  click: -> action 'selectConvIndex', 1
              }, {
                  label: 'Conversation 3'
                  accelerator: getAccelarator('conversation3')
                  click: -> action 'selectConvIndex', 2
              }, {
                  label: 'Conversation 4'
                  accelerator: getAccelarator('conversation4')
                  click: -> action 'selectConvIndex', 3
              }, {
                  label: 'Conversation 5'
                  accelerator: getAccelarator('conversation5')
                  click: -> action 'selectConvIndex', 4
              }, {
                  label: 'Conversation 6'
                  accelerator: getAccelarator('conversation6')
                  click: -> action 'selectConvIndex', 5
              }, {
                  label: 'Conversation 7'
                  accelerator: getAccelarator('conversation7')
                  click: -> action 'selectConvIndex', 6
              }, {
                  label: 'Conversation 8'
                  accelerator: getAccelarator('conversation8')
                  click: -> action 'selectConvIndex', 7
              }, {
                  label: 'Conversation 9'
                  accelerator: getAccelarator('conversation9')
                  click: -> action 'selectConvIndex', 8
              }
            ]
        }, {
            type: 'separator'
        }, {
            label: 'Show tray icon'
            type: 'checkbox'
            enabled: not viewstate.hidedockicon
            checked:  viewstate.showtray
            click: -> action 'toggleshowtray'
        }, {
          label: 'Escape key hides YakYak to tray'
          type: 'checkbox'
          enabled: viewstate.showtray
          checked: viewstate.escapeClosesWindow
          click: -> action 'toggleescapecloseswindow'
        }
        if isDarwin
            {
                label: 'Hide Dock icon'
                type: 'checkbox'
                enabled: viewstate.showtray
                checked:  viewstate.hidedockicon
                click: -> action 'togglehidedockicon'
            }
    ].filter (n) -> n != undefined

templateWindow = (viewstate) -> [
    {
        label: 'Minimize'
        accelerator: getAccelerator('minimize')
        selector: 'performMiniaturize:' if isDarwin
    }, {
        label: 'Close'
        accelerator: getAccelerator('close')
        selector: 'performClose:' if isDarwin
    }, {
        type: 'separator'
    }, {
        label: 'Bring All to Front',
        selector: 'arrangeInFront:' if isDarwin
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
        }, {
            label: 'Edit'
            submenu: templateEdit viewstate
        },{
            label: 'View'
            submenu: templateView viewstate
        }
        if isDarwin
            {
                label: 'Window'
                submenu: templateWindow viewstate
            }
    ].filter (n) -> n != undefined

module.exports = (viewstate) ->
    Menu.setApplicationMenu Menu.buildFromTemplate templateMenu(viewstate)
