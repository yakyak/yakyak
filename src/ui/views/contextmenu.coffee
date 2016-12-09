remote      = require('electron').remote
contextMenu = require('electron-context-menu')
clipboard   = require('electron').clipboard
trifl       = require 'trifl'

trifl.expose window

module.exports = (viewstate) ->
    contextMenu {
        window: remote.getCurrentWindow()
        showInspectElement: false
        prepend: (params, browserWindow) ->
            showNonEnabled = !params.isEditable &&
                params.selectionText == ''
            [{
                label: 'Select All'
                role: 'selectall'
                visible: params.isEditable
            }
            # These two are just for visual consistency as when
            #  it is possible to copy/paste, it will show default copy/paste
            {
                label: 'Cut'
                enabled: false
                # only show it when right-clicking images
                visible: showNonEnabled
            }
            {
                label: 'Copy'
                enabled: false
                # only show it when right-clicking images
                visible: showNonEnabled
            }
            ]
        append: (params, browserWindow) ->
            formats = clipboard.availableFormats()
            pasteableContent = ['text/plain', 'image/png']
            hasPasteableContent = false
            for content in formats
                hasPasteableContent |= pasteableContent.includes(content)
            [{
                label: 'Paste to message'
                enabled: true
                # only show it when right-clicking images
                visible: hasPasteableContent && !params.isEditable &&
                    viewstate.state == viewstate.STATE_NORMAL
                click: () ->
                    formats = clipboard.availableFormats()
                    if formats.includes 'text/plain'
                        action 'pastetext', clipboard.readText()
                    else if formats.includes 'image/png'
                        action 'onpasteimage'
            }]
    }
