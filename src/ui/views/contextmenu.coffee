remote      = require('electron').remote
clipboard   = require('electron').clipboard
# {download}  = require('electron-dl') # See IMPORTANT below
ContextMenu = remote.Menu

{isContentPasteable} = require '../util'

templateContext = (params, viewstate) ->

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
        role: 'paste'
        visible: (isContentPasteable() &&
            viewstate.state == viewstate.STATE_NORMAL) || params.isEditable
    }].filter (n) -> n != undefined

module.exports = (e, viewstate) ->
    ContextMenu.buildFromTemplate templateContext(e, viewstate)
