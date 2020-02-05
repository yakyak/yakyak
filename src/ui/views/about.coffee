ipc    = require('electron').ipcRenderer
path   = require 'path'
i18n   = require 'i18n'
React  = require('react')

{check, versionToInt} = require '../version'

module.exports = view (models) ->
    #
    # decide if should update
    localVersion    = ipc.sendSync "app:version"
    releasedVersion = window.localStorage.versionAdvertised
    shouldUpdate    = releasedVersion? && localVersion? &&
                      versionToInt(releasedVersion) > versionToInt(localVersion)
    #
    div id: 'about-react', class: 'about', 'nothing to see here'

#$('document').on 'click', '.link-out', (ev)->
#
