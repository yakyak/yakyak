
request = require 'request'

options =
  headers:
    'User-Agent': 'request'
  url: 'https://api.github.com/repos/yakyak/yakyak/releases/latest'

check = ->
  request.get options,  (err, res, body) ->
    body = JSON.parse body
    tag = body.tag_name
    releasedVersion = tag.substr(1) # remove first "v" char
    localVersion = require('electron').remote.require('electron').app.getVersion()
    versionAdvertised = window.localStorage.versionAdvertised or null
    if (releasedVersion isnt localVersion) and (releasedVersion isnt versionAdvertised)
      window.localStorage.versionAdvertised = releasedVersion
      alert "A new yakyak version is available, please upgrade #{localVersion} => #{releasedVersion}"
    else
      console.log "YakYak local version is #{localVersion}, released version is #{releasedVersion}"

module.exports = {check}
