remote = require('electron').remote
Menu = remote.Menu

acceleratorMap = {
    hideyakyak:           {others: 'Control+H', darwin:'Command+H'}
    hideothers:           {others: '', darwin:'Command+Shift+H'}
    showall:              {others: '', darwin:''}
    openinspector:        {others: 'Control+Alt+I', darwin:'Command+Alt+I'}
    quit:                 {others: 'Control+Q', darwin:'Command+Q'}
    undo:                 {others: 'Control+Z', darwin:'Command+Z'}
    redo:                 {others: 'Control+Shift+Z', darwin:'Command+Shift+Z'}
    cut:                  {others: '', darwin:'Command+X'}
    copy:                 {others: '', darwin:'Command+C'}
    paste:                {others: '', darwin:'Command+V'}
    selectall:            {others: '', darwin:'Command+A'}
    togglefullscreen:     {others: 'Control+Alt+F', darwin:'Command+Control+F'}
    zoomin:               {others: 'Control+Plus', darwin:'Command+Plus'}
    zoomout:              {others: 'Control+-', darwin:'Command+-'}
    resetzoom:            {others: 'Control+0', darwin:'Command+0'}
    previousconversation: {others: 'Control+K', darwin:'Command+Shift+Tab'}
    nextconversation:     {others: 'Control+J', darwin:'Command+Tab'}
    conversation1:        {others: 'Alt+1', darwin:'Command+1'}
    conversation2:        {others: 'Alt+2', darwin:'Command+2'}
    conversation3:        {others: 'Alt+3', darwin:'Command+3'}
    conversation4:        {others: 'Alt+4', darwin:'Command+4'}
    conversation5:        {others: 'Alt+5', darwin:'Command+5'}
    conversation6:        {others: 'Alt+6', darwin:'Command+6'}
    conversation7:        {others: 'Alt+7', darwin:'Command+7'}
    conversation8:        {others: 'Alt+8', darwin:'Command+8'}
    conversation9:        {others: 'Alt+9', darwin:'Command+9'}
    minimize:             {others: '', darwin:'Command+M'}
    close:                {others: '', darwin:'Command+W'}
}

templateYakYak = (viewstate, platform) ->
    tmpl = []
    if platform == 'darwin'
        tmpl.concat [
            { label: 'About YakYak', selector: 'orderFrontStandardAboutPanel:' }
            #{ type: 'separator' }
            # { label: 'Preferences...', accelerator: 'Command+,',
            # click: => delegate.openConfig() }
            { type: 'separator' }
        ]
    tmpl.push {
        label: 'Hide YakYak'
        accelerator: acceleratorMap['hideyakyak'][platform]
        selector: 'hide:' if platform == 'darwin'
        role: 'minimize' if platform == 'others'
    }

    if platform == 'darwin'
        tmpl.push [{
                label: 'Hide Others'
                accelerator: acceleratorMap['hideother'][platform]
                selector: 'hideOtherApplications:' if platform == 'darwin'
            }
            {
                label: 'Show All'
                selector: 'unhideAllApplications:' if platform == 'darwin'
            }
        ]
    tmpl.push [
        { type: 'separator' }
        {
            label: 'Open Inspector'
            accelerator: acceleratorMap['openinspector'][platform]
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
            accelerator: acceleratorMap['quit'][platform]
            click: -> action 'quit'
        }
    ]
    tmpl

templateEdit = (viewstate, platform) ->
    tmpl = [
        {
          label: 'Undo'
          accelerator: acceleratorMap['undo'][platform]
          selector: 'undo:' if platform == 'darwin'
          role: 'undo' if platform == 'others'
        }
        {
          label: 'Redo'
          accelerator: acceleratorMap['redo'][platform]
          selector: 'redo:' if platform == 'darwin'
          role: 'redo' if platform == 'others'
        }
    ]
    if platform == 'darwin'
        tmpl.push [
          { type: 'separator' }
          {
            label: 'Cut'
            accelerator: acceleratorMap['cut'][platform]
            selector: 'cut:' if platform == 'darwin'
            role: 'cut' if platform == 'others'
          }
          {
            label: 'Copy'
            accelerator: acceleratorMap['copy'][platform]
            selector: 'copy:' if platform == 'darwin'
            role: 'copy' if platform == 'others'
          }
          {
            label: 'Paste'
            accelerator: acceleratorMap['paste'][platform]
            selector: 'paste:' if platform == 'darwin'
            role: 'paste' if platform == 'others'
          }
          {
            label: 'Select All'
            accelerator: acceleratorMap['selectall'][platform]
            selector: 'selectAll:' if platform == 'darwin'
            role: 'selectall' if platform == 'others'
          }
        ]
    tmpl

templateView = (viewstate, platform) ->
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
            accelerator: acceleratorMap['togglefullscreen'][platform],
            click: -> action 'togglefullscreen'
        }, {
            # seee https://github.com/atom/electron/issues/1507
            label: 'Zoom In',
            accelerator: acceleratorMap['zoomin'][platform],
            click: -> action 'zoom', +0.25
        }, {
            label: 'Zoom Out',
            accelerator: acceleratorMap['zoomout'][platform],
            click: -> action 'zoom', -0.25
        }, {
            label: 'Reset Zoom',
            accelerator: acceleratorMap['resetzoom'][platform],
            click: -> action 'zoom'
        }, {
            type: 'separator'
        }, {
            label: 'Previous Conversation',
            accelerator: acceleratorMap['previousconversation'][platform]
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', -1
        }, {
            label: 'Next Conversation',
            accelerator: acceleratorMap['nextconversation'][platform]
            enabled: viewstate.loggedin
            click: -> action 'selectNextConv', +1
        }, {
            label: 'Select Conversation',
            enabled: viewstate.loggedin
            submenu: [
              {
                  label: 'Conversation 1'
                  accelerator: acceleratorMap['conversation1'][platform]
                  click: -> action 'selectConvIndex', 0
              }, {
                  label: 'Conversation 2'
                  accelerator: acceleratorMap['conversation2'][platform]
                  click: -> action 'selectConvIndex', 1
              }, {
                  label: 'Conversation 3'
                  accelerator: acceleratorMap['conversation3'][platform]
                  click: -> action 'selectConvIndex', 2
              }, {
                  label: 'Conversation 4'
                  accelerator: acceleratorMap['conversation4'][platform]
                  click: -> action 'selectConvIndex', 3
              }, {
                  label: 'Conversation 5'
                  accelerator: acceleratorMap['conversation5'][platform]
                  click: -> action 'selectConvIndex', 4
              }, {
                  label: 'Conversation 6'
                  accelerator: acceleratorMap['conversation6'][platform]
                  click: -> action 'selectConvIndex', 5
              }, {
                  label: 'Conversation 7'
                  accelerator: acceleratorMap['conversation7'][platform]
                  click: -> action 'selectConvIndex', 6
              }, {
                  label: 'Conversation 8'
                  accelerator: acceleratorMap['conversation8'][platform]
                  click: -> action 'selectConvIndex', 7
              }, {
                  label: 'Conversation 9'
                  accelerator: acceleratorMap['conversation9'][platform]
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
    #
    if platform == 'darwin'
        tmpl.push {
            label: 'Hide Dock icon'
            type: 'checkbox'
            enabled: viewstate.showtray
            checked:  viewstate.hidedockicon
            click: -> action 'togglehidedockicon'
        }
    tmpl

templateWindow = (viewstate, platform) -> [
    {
        label: 'Minimize'
        accelerator: acceleratorMap['minimize'][platform]
        selector: 'performMiniaturize:' if platform == 'darwin'
    }, {
        label: 'Close'
        accelerator: acceleratorMap['close'][platform]
        selector: 'performClose:' if platform == 'darwin'
    }, {
        type: 'separator'
    }, {
        label: 'Bring All to Front',
        selector: 'arrangeInFront:' if platform == 'darwin'
    }
]

templateMenu = (viewstate) ->
    platform = if require('os').platform() == 'darwin' then 'darwin' else 'others'
    tmpl = [{
            label: 'YakYak'
            submenu: templateYakYak viewstate, platform
        }, {
            label: 'Edit'
            submenu: templateEdit viewstate, platform
        },{
            label: 'View'
            submenu: templateView viewstate, platform
        }
    ]
    if platform == 'darwin'
        tmpl.push {
            label: 'Window'
            submenu: templateWindow viewstate, platform
        }
    tmpl

module.exports = (viewstate) ->
    Menu.setApplicationMenu Menu.buildFromTemplate templateMenu(viewstate)
