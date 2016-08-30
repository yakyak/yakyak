remote = require('electron').remote
Menu = remote.Menu

templateOsx = (viewstate) -> [{
    label: 'YakYak'
    submenu: [
        { label: 'About YakYak', selector: 'orderFrontStandardAboutPanel:' }
        { type: 'separator' }
        # { label: 'Preferences...', accelerator: 'Command+,', click: => delegate.openConfig() }
        { type: 'separator' }
        { label: 'Hide YakYak', accelerator: 'Command+H', selector: 'hide:' }
        { label: 'Hide Others', accelerator: 'Command+Shift+H', selector: 'hideOtherApplications:' }
        { label: 'Show All', selector: 'unhideAllApplications:' }
        { type: 'separator' }
        { label: 'Open Inspector', accelerator: 'Command+Alt+I', click: -> action 'devtools' }
        { type: 'separator' }
        {
          label: 'Logout',
          click: -> action 'logout'
          enabled: viewstate.loggedin
        }
        { label: 'Quit', accelerator: 'Command+Q', click: -> action 'quit' }
    ]},{
    label: 'Edit'
    submenu: [
        { label: 'Undo', accelerator: 'Command+Z', selector: 'undo:' }
        { label: 'Redo', accelerator: 'Command+Shift+Z', selector: 'redo:' }
        { type: 'separator' }
        { label: 'Cut', accelerator: 'Command+X', selector: 'cut:' }
        { label: 'Copy', accelerator: 'Command+C', selector: 'copy:' }
        { label: 'Paste', accelerator: 'Command+V', selector: 'paste:' }
        { label: 'Select All', accelerator: 'Command+A', selector: 'selectAll:' }
    ]},{
    label: 'View'
    submenu: [
        {
            label: 'Conversation List'
            submenu: [
                {
                    type: 'checkbox'
                    label: 'Show Thumbnails'
                    checked:viewstate.showConvThumbs
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
                    enabled: viewstate.loggedin && viewstate.showConvThumbs
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
            accelerator: 'Command+Control+F',
            click: -> action 'togglefullscreen'
        }, {
            # seee https://github.com/atom/electron/issues/1507
            label: 'Zoom In',
            accelerator: 'Command+Plus',
            click: -> action 'zoom', +0.25
        }, {
            label: 'Zoom Out',
            accelerator: 'Command+-',
            click: -> action 'zoom', -0.25
        }, {
            label: 'Reset Zoom',
            accelerator: 'Command+0',
            click: -> action 'zoom'
        }, {
            type: 'separator'
        }, {
            label: 'Previous Conversation',
            accelerator: 'Control+Shift+Tab'
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', -1
        }, {
            label: 'Next Conversation',
            accelerator: 'Control+Tab'
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', +1
        }, {
            label: 'Select Conversation',
            enabled: viewstate.loggedin
            submenu: [
              {
                label: 'Conversation 1'
                accelerator: 'Command+1'
                click: -> action 'selectConvIndex', 0
              },
              {
                label: 'Conversation 2'
                accelerator: 'Command+2'
                click: -> action 'selectConvIndex', 1
              },
              {
                label: 'Conversation 3'
                accelerator: 'Command+3'
                click: -> action 'selectConvIndex', 2
              },
              {
                label: 'Conversation 4'
                accelerator: 'Command+4'
                click: -> action 'selectConvIndex', 3
              },
              {
                label: 'Conversation 5'
                accelerator: 'Command+5'
                click: -> action 'selectConvIndex', 4
              },
              {
                label: 'Conversation 6'
                accelerator: 'Command+6'
                click: -> action 'selectConvIndex', 5
              },
              {
                label: 'Conversation 7'
                accelerator: 'Command+7'
                click: -> action 'selectConvIndex', 6
              },
              {
                label: 'Conversation 8'
                accelerator: 'Command+8'
                click: -> action 'selectConvIndex', 7
              },
              {
                label: 'Conversation 9'
                accelerator: 'Command+9'
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
            label: 'Hide Dock icon'
            type: 'checkbox'
            enabled: viewstate.showtray
            checked:  viewstate.hidedockicon
            click: -> action 'togglehidedockicon'
        }
    ]}, {
    label: 'Window',
    submenu: [
        {
            label: 'Minimize',
            accelerator: 'Command+M',
            selector: 'performMiniaturize:'
        },
        {
            label: 'Close',
            accelerator: 'Command+W',
            selector: 'performClose:'
        },
        {
            type: 'separator'
        },
        {
            label: 'Bring All to Front',
            selector: 'arrangeInFront:'
        }
      ]
    }
]

# TODO: find proper windows/linux accelerators
templateOthers = (viewstate) -> [{
    label: 'YakYak'
    submenu: [
        { label: 'Hide YakYak', accelerator: 'Control+H', role: 'minimize' }
        { type: 'separator' }
        { label: 'Open Inspector', accelerator: 'Control+Alt+I', click: -> action 'devtools' }
        { type: 'separator' }
        { type: 'separator' }
        {
          label: 'Logout',
          click: -> action 'logout'
          enabled: viewstate.loggedin
        }
        { label: 'Quit', accelerator: 'Control+Q', click: -> action 'quit' }
    ]}, {
    label: 'Edit'
    submenu: [
        { label: 'Undo', accelerator: 'Control+Z', role: 'undo' }
        { label: 'Redo', accelerator: 'Control+Shift+Z', role: 'redo' }
       # { type: 'separator' }
       # { label: 'Cut', accelerator: 'Control+X', role: 'cut' }
       # { label: 'Copy', accelerator: 'Control+C', role: 'copy' }
       # { label: 'Paste', accelerator: 'Control+V', role: 'paste' }
       # { label: 'Select All', accelerator: 'Control+A', role: 'selectall' }
    ]}, {
    label: 'View'
    submenu: [
        {
            label: 'Conversation List'
            submenu: [
                {
                    type: 'checkbox'
                    label: 'Show Thumbnails'
                    checked:viewstate.showConvThumbs
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
                    enabled: viewstate.loggedin && viewstate.showConvThumbs
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
            accelerator: 'Control+Alt+F',
            click: -> action 'togglefullscreen'
        }, {
            # seee https://github.com/atom/electron/issues/1507
            label: 'Zoom In',
            accelerator: 'Control+Plus',
            click: -> action 'zoom', +0.25
        }, {
            label: 'Zoom Out',
            accelerator: 'Control+-',
            click: -> action 'zoom', -0.25
        }, {
            label: 'Reset Zoom',
            accelerator: 'Control+0',
            click: -> action 'zoom'
        }, {
          type: 'separator'
        }, {
            label: 'Previous Conversation',
            accelerator: 'Control+K',
            click: -> action 'selectNextConv', -1
            enabled: viewstate.loggedin
        }, {
            label: 'Next Conversation',
            accelerator: 'Control+J',
            click: -> action 'selectNextConv', +1
            enabled: viewstate.loggedin
        }, {
            label: 'Select Conversation',
            enabled: viewstate.loggedin
            submenu: [
              {
                label: 'Conversation 1'
                accelerator: 'Alt+1'
                click: -> action 'selectConvIndex', 0
              },
              {
                label: 'Conversation 2'
                accelerator: 'Alt+2'
                click: -> action 'selectConvIndex', 1
              },
              {
                label: 'Conversation 3'
                accelerator: 'Alt+3'
                click: -> action 'selectConvIndex', 2
              },
              {
                label: 'Conversation 4'
                accelerator: 'Alt+4'
                click: -> action 'selectConvIndex', 3
              },
              {
                label: 'Conversation 5'
                accelerator: 'Alt+5'
                click: -> action 'selectConvIndex', 4
              },
              {
                label: 'Conversation 6'
                accelerator: 'Alt+6'
                click: -> action 'selectConvIndex', 5
              },
              {
                label: 'Conversation 7'
                accelerator: 'Alt+7'
                click: -> action 'selectConvIndex', 6
              },
              {
                label: 'Conversation 8'
                accelerator: 'Alt+8'
                click: -> action 'selectConvIndex', 7
              },
              {
                label: 'Conversation 9'
                accelerator: 'Alt+9'
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
        }
    ]}
]

module.exports = (viewstate) ->
    if require('os').platform() == 'darwin'
        Menu.setApplicationMenu Menu.buildFromTemplate templateOsx(viewstate)
    else
        Menu.setApplicationMenu Menu.buildFromTemplate templateOthers(viewstate)
