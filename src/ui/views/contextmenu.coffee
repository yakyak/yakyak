remote        = require('electron').remote
clipboard     = require('electron').clipboard
# {download}  = require('electron-dl') # See IMPORTANT below
ContextMenu = remote.Menu

{isContentPasteable} = require '../util'

contents = remote.getCurrentWindow().webContents
session = contents.session
availableLanguages = session.availableSpellCheckerLanguages

templateContext = (params, viewstate) ->
    #
    #          IMPORTANT: currently save images is disabled as there
    #            are exceptions being thrown from the electron-dl module
    #
    canShowSaveImg = params.mediaType == 'image' && false
    canShowCopyImgLink = params.mediaType == 'image' && params.srcURL != ''
    canShowCopyLink = params.linkURL != '' && params.mediaType == 'none'
    #

    spellcheckLanguage = viewstate.spellcheckLanguage
    spellCheck = if spellcheckLanguage == 'none'
        i18n.__('menu.edit.spell_check.off:Spellcheck is off')
    else
        i18n.__('menu.edit.spell_check.title:Spellcheck') + ': ' + spellcheckLanguage

    console.log('ada', spellCheck, params.dictionarySuggestions.map (el) -> { label: el, click: -> contents.replaceMisspelling(el)})
    [
      ...params.dictionarySuggestions.map (el) -> { label: el, click: -> contents.replaceMisspelling(el)}
      {
        type: 'separator'
        visible: params?.dictionarySuggestions?.length > 0
      }
      {
        label: i18n.__('menu.edit.spell_check.title:Spellcheck')
        submenu: [
            {
                label: spellCheck
                enabled: false
                checked: spellcheckLanguage != 'none'
                click: -> action 'setspellchecklanguage', 'none'
            }

            {
              label: i18n.__('menu.edit.spell_check.turn_off:Turn spellcheck off')
              visible: spellcheckLanguage != 'none'
              click: -> action 'setspellchecklanguage', 'none'
            }

            {
                label: i18n.__('menu.edit.spell_check.available:Available languages')
                submenu: availableLanguages.map (el) ->
                    {
                      label: el
                      click: -> action 'setspellchecklanguage', el
                    }
            }
        ]
    }
    { type: 'separator' }
    {
        label: i18n.__('menu.edit.save_image:Save Image')
        visible: canShowSaveImg
        click: (item, win) ->
            try
                download win, params.srcURL
            catch
                console.log 'Possible problem with saving image. ', err
    }
    { type: 'separator' } if canShowSaveImg
    {
        label: i18n.__('menu.edit.undo:Undo')
        role: 'undo'
        enabled: params.editFlags.canUndo
        visible: true
    }
    {
        label: i18n.__('menu.edit.redo:Redo')
        role: 'redo'
        enabled: params.editFlags.canRedo
        visible: true
    }
    { type: 'separator' }
    {
        label: i18n.__('menu.edit.cut:Cut')
        role: 'cut'
        enabled: params.editFlags.canCut
        visible: true
    }
    {
        label: i18n.__('menu.edit.copy:Copy')
        role: 'copy'
        enabled: params.editFlags.canCopy
        visible: true
    }
    {
        label: i18n.__('menu.edit.copy_link:Copy Link')
        visible: canShowCopyLink
        click: () ->
            if process.platform == 'darwin'
                clipboard.writeBookmark params.linkText, params.linkText
            else
                clipboard.writeText params.linkText
    }
    {
        label: i18n.__('menu.edit.copy_image_link:Copy Image Link')
        visible: canShowCopyImgLink
        click: (item, win) ->
            if process.platform == 'darwin'
                clipboard.writeBookmark params.srcURL, params.srcURL
            else
                clipboard.writeText params.srcURL
    }
    {
        label: i18n.__('menu.edit.paste:Paste')
        role: 'paste'
        visible: (isContentPasteable() &&
            viewstate.state == viewstate.STATE_NORMAL) || params.isEditable
    }].filter (n) -> n != undefined

module.exports = (e, viewstate) ->
    ContextMenu.buildFromTemplate templateContext(e, viewstate)
