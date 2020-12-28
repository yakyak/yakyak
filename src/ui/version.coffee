ipc = require('electron').ipcRenderer
got = require 'got'

options =
    headers:
      'User-Agent': 'request'
    url: 'https://api.github.com/repos/yakyak/yakyak/releases/latest'

versionToInt = (version) ->
    [major, minor, micro] = version.split('.')
    version = (micro * Math.pow(10,4)) + (minor * Math.pow(10,8)) + (major * Math.pow(10,12))

check = ()->
    window.localStorage.localVersion = await ipc.invoke "app:version"
    got(options.url)
        .then (res) ->
            body = JSON.parse res.body
            tag = body.tag_name
            releasedVersion   = tag?.substr(1) # remove first "v" char
            localVersion      = window.localStorage.localVersion
            versionAdvertised = window.localStorage.versionAdvertised or null
            if releasedVersion? && localVersion?
                higherVersionAvailable = versionToInt(releasedVersion) > versionToInt(localVersion)
                if higherVersionAvailable and (releasedVersion isnt versionAdvertised)
                    window.localStorage.versionAdvertised = releasedVersion
                    notr {
                        html: "A new YakYak version is available<br/>Please upgrade #{localVersion} to #{releasedVersion}<br/><i style=\"font-size: .9em; color: gray\">(click to dismiss)</i>",
                        stay: 0
                    }
                console.log "YakYak local version is #{localVersion}, released version is #{releasedVersion}"
        .catch (error) ->
            console.log error

module.exports = {check, versionToInt}
