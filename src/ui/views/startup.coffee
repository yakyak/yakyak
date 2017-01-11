path = require 'path'

{later} = require '../util'

module.exports = view (models) ->
    {connection, viewstate} = models
    classList = ['connecting']
    if viewstate.loadedContacts
        classList.push 'hide'

    div class: classList.join(' ')
    , onDOMNodeInserted: (e) ->
        ta = e.target
        ta.addEventListener 'transitionend', ->
            action 'remove_startup'
        , false
    , ->
        div ->
            div ->
                img src: path.join __dirname, '..', '..', 'icons', 'icon@32.png'
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
