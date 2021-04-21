Client = require 'hangupsjs'
Q = require 'q'
{session} = require('electron')
app = require('electron').app

# Current programmatic login workflow is described here
# https://github.com/tdryer/hangups/issues/260#issuecomment-246578670
LOGIN_URL = "https://accounts.google.com/o/oauth2/programmatic_auth?hl=en&scope=https%3A%2F%2Fwww.google.com%2Faccounts%2FOAuthLogin+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email&client_id=936475272427.apps.googleusercontent.com&access_type=offline&delegated_client_id=183697946088-m3jnlsqshjhh5lbvg05k46q1k4qqtrgn.apps.googleusercontent.com&top_level_cookie=1"

# Hack the user agent so this works again
# Credit to https://github.com/yakyak/yakyak/issues/1087#issuecomment-565170640
#
# WARN:: This should be removed in the long term.
AGENT = app.userAgentFallback
    .replace('Chrome', 'Chromium')

# promise for one-time oauth token
module.exports = (mainWindow) -> Q.Promise (rs, reject) ->

    mainWindow.webContents.on 'did-finish-load', onDidFinishLoad = ->

        # the url that just finished loading
        url = mainWindow.getURL()
        console.log 'login: did-finish-load', url

        if url.indexOf('/signin/rejected') > 0 and url.indexOf('rrk=47') > 0
            console.error 'javascript disabled, testing logout...'
            reject 'logout'

        else if url.indexOf('/o/oauth2/programmatic_auth') > 0
            console.log 'login: programmatic auth'
            # get the cookie from browser session, it has to be there
            session.defaultSession.cookies.get({})
            .then (values=[]) ->
                oauth_code = false
                for value in values
                    if value.name is 'oauth_code'
                        oauth_code = value.value
                rs(oauth_code) if oauth_code
            .catch (err) ->
                console.log 'login: ERROR retrieving cookies::', err

    # redirect to google oauth
    options = {"userAgent": AGENT}
    mainWindow.loadURL LOGIN_URL, options
