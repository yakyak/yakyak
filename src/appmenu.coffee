Menu = require 'menu'

attach = (app, delegate) ->
  menus = []
  menus.push
    label: 'YakYak'
    submenu: [
      { label: 'About YakYak', selector: 'orderFrontStandardAboutPanel:' }
      { type: 'separator' }
      # { label: 'Preferences...', accelerator: 'Command+,', click: => delegate.openConfig() }
      { type: 'separator' }
      { label: 'Hide Atom', accelerator: 'Command+H', selector: 'hide:' }
      { label: 'Hide Others', accelerator: 'Command+Shift+H', selector: 'hideOtherApplications:' }
      { label: 'Show All', selector: 'unhideAllApplications:' }
      { type: 'separator' }
      { label: 'Open Inspector', accelerator: 'Command+Alt+I', click: => delegate.openDevTools() }
      { type: 'separator' }
      { label: 'Quit', accelerator: 'Command+Q', click: -> app.quit() }
    ]
  menus.push
    label: 'Edit'
    submenu: [
      { label: 'Undo', accelerator: 'Command+Z', selector: 'undo:' }
      { label: 'Redo', accelerator: 'Command+Shift+Z', selector: 'redo:' }
      { type: 'separator' }
      { label: 'Cut', accelerator: 'Command+X', selector: 'cut:' }
      { label: 'Copy', accelerator: 'Command+C', selector: 'copy:' }
      { label: 'Paste', accelerator: 'Command+V', selector: 'paste:' }
      { label: 'Select All', accelerator: 'Command+A', selector: 'selectAll:' }
    ]
  Menu.setApplicationMenu Menu.buildFromTemplate menus

module.exports = {attach}
