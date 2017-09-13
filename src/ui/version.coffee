
request = require 'request'

options =
    headers:
      'User-Agent': 'request'
    url: 'https://api.github.com/repos/yakyak/yakyak/releases/latest'

versionToInt = (version) ->
    [major, minor, micro] = version.split('.')
    version = (micro * 10^3) + (minor * 10^6) + (major * 10^9)

check = ()->
    request.get options,  (err, res, body) ->
        return console.log err if err
        body = JSON.parse body
        tag = body.tag_name
        releasedVersion = tag?.substr(1) # remove first "v" char
        localVersion = require('electron').remote.require('electron').app.getVersion()
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

module.exports = {check, versionToInt}
