ipc  = require('electron').ipcRenderer
path = require 'path'
i18n = require 'i18n'
remote = require('electron').remote
Menu   = remote.Menu

{check, versionToInt} = require '../version'

module.exports = view (models) ->

    # simple context menu that can only copy
    remote.getCurrentWindow().webContents.on 'context-menu', (e, params) ->
        e.preventDefault()
        menuTemplate = [{
            label: 'Copy'
            role: 'copy'
            enabled: params.editFlags.canCopy
        }
        {
            label: "Copy Link"
            visible: params.linkURL != '' and params.mediaType == 'none'
            click: () ->
                if process.platform == 'darwin'
                    clipboard
                    .writeBookmark params.linkText, params.linkText
                else
                    clipboard.writeText params.linkText
        }]
        Menu.buildFromTemplate(menuTemplate).popup remote.getCurrentWindow()

    #
    # decide if should update
    localVersion    = remote.require('electron').app.getVersion()
    releasedVersion = window.localStorage.versionAdvertised
    shouldUpdate    = releasedVersion? && localVersion? &&
                      versionToInt(releasedVersion) > versionToInt(localVersion)
    #
    div class: 'about', ->
        div ->
            img src: path.join YAKYAK_ROOT_DIR, 'icons', 'icon@8.png'
        div class: 'name', ->
            h2 ->
                span 'YakYak v' + localVersion
                span class: 'f-small f-no-bold', ' (latest)' unless shouldUpdate
        # TODO: if objects are undefined then it should check again on next
        #        time about window is opened
        #        releasedVersion = window.localStorage.versionAdvertised
        if shouldUpdate
            div class: 'update', ->
                span i18n.__('menu.help.about.newer:A newer version is available, please upgrade from %s to %s'
                             , localVersion
                             , releasedVersion)
        div class: 'description', ->
            span i18n.__('title:YakYak - Hangouts Client')
        div class: 'license', ->
            span ->
                em "#{i18n.__ 'menu.help.about.license:License'}: "
                span 'MIT'
        div class: 'devs', ->
            div ->
                h3 i18n.__('menu.help.about.authors:Main authors')
                ul ->
                    li 'Davide Bertola'
                    li 'Martin Algesten'
            div ->
                h3 i18n.__('menu.help.about.contributors:Contributors')
                ul ->
                    li 'David Banham'
                    li 'Max Kueng'
                    li 'Arnaud Riu'
                    li 'Austin Guevara'
                    li 'André Veríssimo'
        div class: 'home', ->
            href = "https://github.com/yakyak/yakyak"
            a href: href
            , onclick: (ev) ->
                ev.preventDefault()
                address = ev.currentTarget.getAttribute 'href'
                require('electron').shell.openExternal address
                false
            , href

#$('document').on 'click', '.link-out', (ev)->
#
