remote = require 'remote'
Menu = remote.require 'menu'

template = (viewstate) -> [{
    label: 'Yakyak'
    submenu: [
        { label: 'About YakYak', selector: 'orderFrontStandardAboutPanel:' }
        { type: 'separator' }
        # { label: 'Preferences...', accelerator: 'Command+,', click: => delegate.openConfig() }
        { type: 'separator' }
        { label: 'Hide Atom', accelerator: 'Command+H', selector: 'hide:' }
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
        }
    ]}
]

module.exports = (viewstate) ->
    Menu.setApplicationMenu Menu.buildFromTemplate template(viewstate)
