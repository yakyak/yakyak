remote = require 'remote'
Menu = remote.require 'menu'

templateOsx = (viewstate) -> [{
    label: 'Yakyak'
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
        { label: 'Logout', click: -> action 'logout' }
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
            type:'checkbox'
            label: 'Show Conversation Thumbnails'
            checked:viewstate.showConvThumbs
            click: (it) -> action 'showconvthumbs', it.checked
        }, {
            label: 'Enter Full Screen',
            accelerator: 'Command+Control+F',
            click: -> action 'togglefullscreen'
        }, {
            label: 'Previous Conversation',
            click: -> action 'selectNextConv', -1
        }, {
            label: 'Next Conversation',
            click: -> action 'selectNextConv', +1
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
    label: 'Yakyak'
    submenu: [
        { label: 'Open Inspector', accelerator: 'Command+Alt+I', click: -> action 'devtools' }
        { type: 'separator' }
        { label: 'Logout', click: -> action 'logout' }
        { label: 'Quit', accelerator: 'Command+Q', click: -> action 'quit' }
    ]}, {
    label: 'View'
    submenu: [
        {
            type:'checkbox'
            label: 'Show Conversation Thumbnails'
            checked:viewstate.showConvThumbs
            click: (it) -> action 'showconvthumbs', it.checked
        }, {
            label: 'Enter Full Screen',
            accelerator: 'Command+Control+F',
            click: -> action 'togglefullscreen'
        }, {
            label: 'Previous Conversation',
            click: -> action 'selectNextConv', -1
        }, {
            label: 'Next Conversation',
            click: -> action 'selectNextConv', +1
        }
    ]}
]

module.exports = (viewstate) ->
    if require('os').platform() == 'darwin'
        Menu.setApplicationMenu Menu.buildFromTemplate templateOsx(viewstate)
    else
        Menu.setApplicationMenu Menu.buildFromTemplate templateOthers(viewstate)
