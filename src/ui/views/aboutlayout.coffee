ipc  = require('electron').ipcRenderer
path = require 'path'

remote = require('electron').remote

{check, versionToInt} = require '../version'

trifl = require 'trifl'
trifl.expose window

# expose some selected tagg functions
trifl.tagg.expose window, ('ul li div span a i b u s button p label
input table thead tbody tr td th textarea br pass img h1 h2 h3 h4
hr em'.split(' '))...

attachListeners = ->
    return
    # do nothing

check(true)
releasedVersion = window.localStorage.versionAdvertised
localVersion = remote.require('electron').app.getVersion()

module.exports = exp = layout ->
    div class: 'about', ->
        div ->
            img src: path.join __dirname, '..', '..', 'icons', 'icon@8.png'
        div class: 'name', ->
            h2 'YakYak v' + localVersion
        # TODO: if objects are undefined then it should check again on next
        #        time about window is opened
        if releasedVersion? && localVersion? && versionToInt(releasedVersion) > versionToInt(localVersion)
            div class: 'update', ->
                span 'A newer version is available, please upgrade from ' +
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
    attachListeners()

#$('document').on 'click', '.link-out', (ev)->
#
