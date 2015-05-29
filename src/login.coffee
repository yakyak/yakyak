Client = require 'hangupsjs'
Q = require 'q'

# promise for one-time oauth token
module.exports = (mainWindow) -> Q.Promise (rs) ->

    mainWindow.webContents.on 'did-finish-load', onDidFinishLoad = ->

        # the url that just finished loading
        url = mainWindow.getUrl()

        # when we find this part of the url, we must progress page to /approval
        if url.indexOf('&response_type=code') > 0
            scr = "document.getElementById('connect_approve').submit()"
            mainWindow.webContents.executeJavaScript scr

        # this is the approval page from which we fish out the one-time token
        if url.indexOf('/o/oauth2/approval') > 0
            # Title is: "Success code=4/nWublGccArjDWMn37a7UGSC2TFG7pU"
            title = mainWindow.webContents.getTitle()
            # just get the code out of the title
            code = title.substring 13
            # clean up
            mainWindow.webContents.removeListener 'did-finish-load', onDidFinishLoad
            # and return it to the auth
            rs code

    # redirect to google oauth
    mainWindow.loadUrl Client.OAUTH2_LOGIN_URL
