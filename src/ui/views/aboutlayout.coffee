ipc  = require('electron').ipcRenderer
path = require 'path'
i18n = require 'i18n'
remote = require('electron').remote

{check, versionToInt} = require '../version'

trifl = require 'trifl'

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

module.exports = exp = trifl.layout ->
    div class: 'about', ->
        div ->
            span onclick: (e) ->
                window.close()
            , ->
                span class: 'close-me material-icons', ''
        div ->
            img src: path.join __dirname, '..', '..', 'icons', 'icon@8.png'
        div class: 'name', ->
            h2 'YakYak v' + localVersion
        # TODO: if objects are undefined then it should check again on next
        #        time about window is opened
        if releasedVersion? && localVersion? && versionToInt(releasedVersion) > versionToInt(localVersion)
            div class: 'update', ->
                span i18n.__('menu.help.about.newer'
                             , localVersion
                             , releasedVersion)
        div class: 'description', ->
            span i18n.__('title')
        div class: 'license', ->
            span ->
                em "#{i18n.__ 'menu.help.about.license'}: "
                span 'MIT'
        div class: 'devs', ->
            div ->
                h3 i18n.__('menu.help.about.authors')
                ul ->
                    li 'Davide Bertola'
                    li 'Martin Algesten'
            div ->
                h3 i18n.__('menu.help.about.contributors')
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
