remote = require 'remote'
Menu = remote.require 'menu'

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
            type: 'checkbox'
            label: 'Show Conversation Thumbnails'
            checked:viewstate.showConvThumbs
            enabled: viewstate.loggedin
            click: (it) -> action 'showconvthumbs', it.checked
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
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', -1
        }, {
            label: 'Next Conversation',
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', +1
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
    ]},{
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
    label: 'View'
    submenu: [
        {
            type:'checkbox'
            label: 'Show Conversation Thumbnails'
            checked:viewstate.showConvThumbs
            enabled: viewstate.loggedin
            click: (it) -> action 'showconvthumbs', it.checked
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
