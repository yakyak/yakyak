remote      = require('electron').remote
clipboard   = require('electron').clipboard
# {download}  = require('electron-dl') # See IMPORTANT below
ContextMenu = remote.Menu

templateContext = (params, viewstate) ->
    formats = clipboard.availableFormats()
    pasteableContent = ['text/plain', 'image/png']
    hasPasteableContent = 0
    for content in formats
        hasPasteableContent += pasteableContent.includes(content)
    hasPasteableContent = hasPasteableContent > 0
    #
    #          IMPORTANT: currently save images is disabled as there
    #            are exceptions being thrown from the electron-dl module
    #
    canShowSaveImg = params.mediaType == 'image' && false
    canShowCopyImgLink = params.mediaType == 'image' && params.srcURL != ''
    canShowCopyLink = params.linkURL != '' && params.mediaType == 'none'
    #
    [{
        label: 'Save Image'
        visible: canShowSaveImg
        click: (item, win) ->
            try
                download win, params.srcURL
            catch
                console.log 'Possible problem with saving image. ', err
    }
    { type: 'separator' } if canShowSaveImg
    {
        label: 'Undo'
        role: 'undo'
        enabled: params.editFlags.canUndo
        visible: true
    }
    {
        label: 'Redo'
        role: 'redo'
        enabled: params.editFlags.canRedo
        visible: true
    }
    { type: 'separator' }
    {
        label: 'Cut'
        role: 'cut'
        enabled: params.editFlags.canCut
        visible: true
    }
    {
        label: 'Copy'
        role: 'copy'
        enabled: params.editFlags.canCopy
        visible: true
    }
    {
        label: "Copy Link"
        visible: canShowCopyLink
        click: () ->
            if process.platform == 'darwin'
                clipboard.writeBookmark params.linkText, params.linkText
            else
                clipboard.writeText params.linkText
    }
    {
        label: 'Copy Image Link'
        visible: canShowCopyImgLink
        click: (item, win) ->
            if process.platform == 'darwin'
                clipboard.writeBookmark params.srcURL, params.srcURL
            else
                clipboard.writeText params.srcURL
    }
    {
        label: 'Paste'
        role: 'paste' if params.isEditable
        visible: (hasPasteableContent || params.isEditable)
        enabled: hasPasteableContent
        # if there is a role, then click is ignored
        click: () ->
            if viewstate.state == viewstate.STATE_NORMAL
                formats = clipboard.availableFormats()
                if formats.includes 'text/plain'
                    action 'pastetext', clipboard.readText()
                else if formats.includes 'image/png'
                    action 'onpasteimage'
    }].filter (n) -> n != undefined

module.exports = (e, viewstate) ->
    ContextMenu.buildFromTemplate templateContext(e, viewstate)
