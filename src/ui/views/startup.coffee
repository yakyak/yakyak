path = require 'path'

module.exports = view (models) ->
    {connection, viewstate} = models
    classList = ['connecting']
    if viewstate.loadedContacts
        classList.push 'hide'

    div class: classList.join(' '), ->
        div ->
            div ->
                img src: path.join __dirname, '..', '..', 'icons', 'icon@32.png'
            div ->
                span class: 'text state_connecting', ->
                    if connection.state == connection.CONNECTING
                        'Connecting'
                    else if connection.state == connection.CONNECT_FAILED
                        'Not Connected (check connection)'
                    else
                        # connection.CONNECTED
                        'Loading contacts'
            div class: 'spinner', ->
                div class: 'bounce1', ''
                div class: 'bounce2', ''
                div class: 'bounce3', ''
