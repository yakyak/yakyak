remote = require('electron').remote
os = require('os')
Menu = remote.Menu

acceleratorMap = {
    hideyakyak:           {others: 'Control+H', osx: 'Command+H'}
    hideothers:           {others: '', osx: 'Command+Shift+H'}
    showall:              {others: '', osx: ''}
    openinspector:        {others: 'Control+Alt+I', osx: 'Command+Alt+I'}
    quit:                 {others: 'Control+Q', osx: 'Command+Q'}
    undo:                 {others: 'Control+Z', osx: 'Command+Z'}
    redo:                 {others: 'Control+Shift+Z', osx: 'Command+Shift+Z'}
    cut:                  {others: '', osx: 'Command+X'}
    copy:                 {others: '', osx: 'Command+C'}
    paste:                {others: '', osx: 'Command+V'}
    selectall:            {others: '', osx: 'Command+A'}
    togglefullscreen:     {others: 'Control+Alt+F', osx: 'Command+Control+F'}
    zoomin:               {others: 'Control+Plus', osx: 'Command+Plus'}
    zoomout:              {others: 'Control+-', osx: 'Command+-'}
    resetzoom:            {others: 'Control+0', osx: 'Command+0'}
    previousconversation: {others: 'Control+K', osx: 'Command+Shift+Tab'}
    nextconversation:     {others: 'Control+J', osx: 'Command+Tab'}
    conversation1:        {others: 'Alt+1', osx: 'Command+1'}
    conversation2:        {others: 'Alt+2', osx: 'Command+2'}
    conversation3:        {others: 'Alt+3', osx: 'Command+3'}
    conversation4:        {others: 'Alt+4', osx: 'Command+4'}
    conversation5:        {others: 'Alt+5', osx: 'Command+5'}
    conversation6:        {others: 'Alt+6', osx: 'Command+6'}
    conversation7:        {others: 'Alt+7', osx: 'Command+7'}
    conversation8:        {others: 'Alt+8', osx: 'Command+8'}
    conversation9:        {others: 'Alt+9', osx: 'Command+9'}
    minimize:             {others: '', osx: 'Command+M'}
    close:                {others: '', osx: 'Command+W'}
}

templateYakYak = (viewstate) ->
    tmpl = []
    if os.platform() == 'darwin'
        tmpl.push [
            { label: 'About YakYak', selector: 'orderFrontStandardAboutPanel:' }
            #{ type: 'separator' }
            # { label: 'Preferences...', accelerator: 'Command+,',
            # click: => delegate.openConfig() }
            { type: 'separator' }
        ]
    tmpl.push [
        {
            label: 'Hide YakYak'
            accelerator: acceleratorMap['hideyakyak'][os]
            selector: 'hide:'
        }
    ]

    if os.platform() == 'darwin'
        tmpl.push [{
              label: 'Hide Others'
              accelerator: acceleratorMap['hideother'][os]
              selector: 'hideOtherApplications:'
        }
        { label: 'Show All', selector: 'unhideAllApplications:' }
        ]
    tmpl.push [
      { type: 'separator' }
      {
          label: 'Open Inspector'
          accelerator: acceleratorMap['openinspector'][os]
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
          accelerator: acceleratorMap['quit'][os]
          click: -> action 'quit'
      }
  ]

templateEdit = (viewstate) ->
    tmpl = [
        { label: 'Undo', accelerator: acceleratorMap['undo'][os], selector: 'undo:' }
        { label: 'Redo', accelerator: acceleratorMap['redo'][os], selector: 'redo:' }
    ]
    if os.platform() == 'darwin'
        tmpl.push [
          { type: 'separator' }
          { label: 'Cut', accelerator: acceleratorMap['cut'][os], selector: 'cut:' }
          { label: 'Copy', accelerator: acceleratorMap['copy'][os], selector: 'copy:' }
          { label: 'Paste', accelerator: acceleratorMap['paste'][os], selector: 'paste:' }
          { label: 'Select All', accelerator: acceleratorMap['selectall'][os], selector: 'selectAll:' }
        ]
    tmpl

templateView = (viewstate) ->
    tmpl = [
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
            accelerator: acceleratorMap['togglefullscreen'][os],
            click: -> action 'togglefullscreen'
        }, {
            # seee https://github.com/atom/electron/issues/1507
            label: 'Zoom In',
            accelerator: acceleratorMap['zoomin'][os],
            click: -> action 'zoom', +0.25
        }, {
            label: 'Zoom Out',
            accelerator: acceleratorMap['zoomout'][os],
            click: -> action 'zoom', -0.25
        }, {
            label: 'Reset Zoom',
            accelerator: acceleratorMap['resetzoom'][os],
            click: -> action 'zoom'
        }, {
            type: 'separator'
        }, {
            label: 'Previous Conversation',
            accelerator: acceleratorMap['previousconversation'][os]
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', -1
        }, {
            label: 'Next Conversation',
            accelerator: acceleratorMap['nextconversation'][os]
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', +1
        }, {
            label: 'Select Conversation',
            enabled: viewstate.loggedin
            submenu: [
              {
                  label: 'Conversation 1'
                  accelerator: acceleratorMap['conversation1'][os]
                  click: -> action 'selectConvIndex', 0
              }, {
                  label: 'Conversation 2'
                  accelerator: acceleratorMap['conversation2'][os]
                  click: -> action 'selectConvIndex', 1
              }, {
                  label: 'Conversation 3'
                  accelerator: acceleratorMap['conversation3'][os]
                  click: -> action 'selectConvIndex', 2
              }, {
                  label: 'Conversation 4'
                  accelerator: acceleratorMap['conversation4'][os]
                  click: -> action 'selectConvIndex', 3
              }, {
                  label: 'Conversation 5'
                  accelerator: acceleratorMap['conversation5'][os]
                  click: -> action 'selectConvIndex', 4
              }, {
                  label: 'Conversation 6'
                  accelerator: acceleratorMap['conversation6'][os]
                  click: -> action 'selectConvIndex', 5
              }, {
                  label: 'Conversation 7'
                  accelerator: acceleratorMap['conversation7'][os]
                  click: -> action 'selectConvIndex', 6
              }, {
                  label: 'Conversation 8'
                  accelerator: acceleratorMap['conversation8'][os]
                  click: -> action 'selectConvIndex', 7
              }, {
                  label: 'Conversation 9'
                  accelerator: acceleratorMap['conversation9'][os]
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
    ]
    if os.platform() == 'darwin'
        tmpl.push {
            label: 'Hide Dock icon'
            type: 'checkbox'
            enabled: viewstate.showtray
            checked:  viewstate.hidedockicon
            click: -> action 'togglehidedockicon'
        }
    tmpl

templateWindow = (viewstate) -> [
    {
        label: 'Minimize'
        accelerator: acceleratorMap['minimize'][os]
        selector: 'performMiniaturize:'
    }, {
        label: 'Close'
        accelerator: acceleratorMap['close'][os]
        selector: 'performClose:'
    }, {
        type: 'separator'
    }, {
        label: 'Bring All to Front',
        selector: 'arrangeInFront:'
    }
]

templateMenu = (viewstate) ->
    tmpl = [{
            label: 'YakYak'
            submenu: templateYakYak viewstate
        }, {
            label: 'Edit'
            submenu: templateEdit viewstate
        },{
            label: 'View'
            submenu: templateView viewstate
        }
    ]
    if os.platform() == 'darwin'
        tmpl.push {
            label: 'Window'
            submenu: templateWindow viewstate
        }
    tmpl

module.exports = (viewstate) ->
    Menu.setApplicationMenu Menu.buildFromTemplate templateMenu(viewstate)
