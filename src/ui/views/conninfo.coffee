
icons =
    connect_failed: 'icon-block brand-warning'
    connecting:     'icon-spin1 animate-spin'
    connected:      'icon-check brand-success'

module.exports = view (connection) ->
    div ->
        pass connection.infoText(), ' ', -> span class:icons[connection.state]
