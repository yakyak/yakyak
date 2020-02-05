path   = require 'path'
i18n   = require 'i18n'
remote = require('electron').remote
Menu   = remote.Menu
React  = require('react')

{check, versionToInt} = require '../version'

class AboutComponent extends React.Component
    render: ->
        #
        # Change thes context menu
        #   Only allows copy on it!
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

        # Link to github (reused below)
        githubLink = "https://github.com/yakyak/yakyak"

        React.createElement 'div', {},
            React.createElement 'img', title: 'YakYak logo', src: path.join YAKYAK_ROOT_DIR, '..', 'icons', 'icon@8.png'
            React.createElement 'div', className: 'name',
                   React.createElement 'h2', {},
                         React.createElement 'span', {}, 'YakYak v' + localVersion
                         React.createElement 'span', className: 'f-small f-no-bold', ' (latest)' unless shouldUpdate
            # TODO: if objects are undefined then it should check again on next
            #        time about window is opened
            #        releasedVersion = window.localStorage.versionAdvertised
            if shouldUpdate
                React.createElement 'div', className: 'update',
                    React.createElement 'span', {}, i18n.__('menu.help.about.newer:A newer version is available, please upgrade from %s to %s'
                    , localVersion
                    , releasedVersion)
            React.createElement 'div', className: 'description',
                React.createElement 'span', {}, i18n.__('title:YakYak - Hangouts Client')
            React.createElement 'div', className: 'license',
                React.createElement 'span', {},
                    React.createElement 'em', {}, "#{i18n.__ 'menu.help.about.license:License'}: "
                    React.createElement 'span', {}, 'MIT'
            React.createElement 'div', className: 'devs',
                React.createElement 'div', {},
                    React.createElement 'h3', {}, i18n.__('menu.help.about.authors:Main authors')
                    React.createElement 'ul', {},
                        React.createElement 'li', {}, 'André Veríssimo'
                        React.createElement 'li', {}, 'Davide Bertola'
                        React.createElement 'li', {}, 'Martin Algesten'
                React.createElement 'div', ->
                    React.createElement 'h3', {}, i18n.__('menu.help.about.contributors:Contributors')
                    React.createElement 'ul', {},
                        React.createElement 'li', {}, 'David Banham'
                        React.createElement 'li', {}, 'Max Kueng'
                        React.createElement 'li', {}, 'Arnaud Riu'
                        React.createElement 'li', {}, 'Austin Guevara'
            React.createElement 'div', className: 'home',
                React.createElement 'a', href: githubLink
                , onClick: (ev) ->
                    ev.preventDefault()
                    address = ev.currentTarget.getAttribute 'href'
                    require('electron').shell.openExternal address
                    false
                , githubLink

module.exports = AboutComponent
