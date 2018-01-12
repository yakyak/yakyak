
request = require 'request'

options =
    headers:
      'User-Agent': 'request'
    url: 'https://api.github.com/repos/yakyak/yakyak/releases/latest'

versionToInt = (version) ->
    [major, minor, micro] = version.split('.')
    version = (micro * Math.pow(10,4)) + (minor * Math.pow(10,8)) + (major * Math.pow(10,12))

check = ()->
    request.get options,  (err, res, body) ->
        return console.log err if err
        body = JSON.parse body
        tag = body.tag_name
        releasedVersion = tag?.substr(1) # remove first "v" char
        localVersion = require('electron').remote.require('electron').app.getVersion()
        versionAdvertised = window.localStorage.versionAdvertised or null
        console.log('released', releasedVersion, releasedVersion.split('.'), versionToInt(releasedVersion))
        console.log('local', localVersion, localVersion.split('.'), versionToInt(localVersion))
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
