Client = require 'hangupsjs'
Q      = require 'q'

client = new Client()

app = require 'app'
BrowserWindow = require 'browser-window'

mainWindow = null

# Quit when all windows are closed.
app.on 'window-all-closed', ->
    app.quit() # if (process.platform != 'darwin')

app.on 'ready', ->

    # Create the browser window.
    mainWindow = new BrowserWindow {width: 800, height: 600}

    # promise for one-time oauth token
    creds = -> auth: -> Q.Promise (rs) ->
        # redirect to google oauth
        mainWindow.loadUrl Client.OAUTH2_LOGIN_URL
        mainWindow.webContents.on 'did-finish-load', onDidFinishLoad = ->

            url = mainWindow.getUrl()

            # when we find this part of the url, we must progress page to /approval
            if url.indexOf('&response_type=code') > 0
                scr = "document.getElementById('connect_approve').submit()"
                mainWindow.webContents.executeJavaScript scr

            # this is the approval page from which we fish out the one-time token
            if url.indexOf('/o/oauth2/approval') > 0
                # Success code=4/nWublGccArjDWMn37a7UGSC2TFG7pU
                title = mainWindow.webContents.getTitle()
                code = title.substring 13
                # this is the code to return
                rs code
                # clean up
                mainWindow.webContents.removeListener 'did-finish-load', onDidFinishLoad


    client.connect(creds).then ->
        console.log 'connected'
    .done()

    # and load the index.html of the app.
    # mainWindow.loadUrl 'file://' + __dirname + '/index.html'

    # Emitted when the window is closed.
    mainWindow.on 'closed', ->
        mainWindow = null
