ipc    = require('electron').ipcRenderer
path   = require 'path'
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
            span onclick: (e) ->
                window.close()
            , ->
                span class: 'close-me material-icons', ''
        div ->
            img src: path.join __dirname, '..', '..', 'icons', 'icon@8.png'
        div class: 'name', ->
            h2 ->
                span 'YakYak v' + localVersion
                span class: 'f-small f-no-bold', ' (latest)' unless shouldUpdate
        # TODO: if objects are undefined then it should check again on next
        #        time about window is opened
        #        releasedVersion = window.localStorage.versionAdvertised
        if shouldUpdate
            div class: 'update', ->
                span ->
                    'A newer version is available, please upgrade from ' +
                        localVersion + ' to ' + releasedVersion
        div class: 'description', ->
            span 'Desktop client for Google Hangouts'
        div class: 'license', ->
            span ->
                em 'License: '
                span 'MIT'
        div class: 'devs', ->
            div ->
                h3 'Main authors'
                ul ->
                    li 'Davide Bertola'
                    li 'Martin Algesten'
            div ->
                h3 'Contributors'
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
