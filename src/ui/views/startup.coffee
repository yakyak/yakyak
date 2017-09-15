path = require 'path'

{later} = require '../util'

module.exports = view (models) ->
    {connection, viewstate} = models
    classList = ['connecting']
    if viewstate.loadedContacts
        classList.push 'hide'

    div class: classList.join(' '), ->
        div ->
            div ->
                img src: path.join YAKYAK_ROOT_DIR, '..', 'icons', 'icon@32.png'
            div ->
                span class: 'text state_connecting', ->
                    if connection.state == connection.CONNECTING
                        i18n.__ 'connection.connecting:Connecting'
                    else if connection.state == connection.CONNECT_FAILED
                        i18n.__ 'connection.connecting:Not Connected (check connection)'
                    else
                        # connection.CONNECTED
                        i18n.__ 'connection.connecting:Loading contacts'
            div class: 'spinner', ->
                div class: 'bounce1', ''
                div class: 'bounce2', ''
                div class: 'bounce3', ''
