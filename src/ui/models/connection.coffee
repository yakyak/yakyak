
STATE =
    CONNECTING:     'connecting'     # exactly match corresponding event name
    CONNECTED:      'connected'      # exactly match corresponding event name
    CONNECT_FAILED: 'connect_failed' # exactly match corresponding event name

merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t

info =
    connecting:     'Connecting…'
    connected:      'Connected'
    connect_failed: 'Not connected'
    unknown:         'Unknown'

module.exports = exp =
    state: null     # current connection state
    lastActive: null  # last activity timestamp

    setState: (state) ->
        return if @state == state
        @state = state
        updated 'connection'

    infoText: -> info[@state] ? info.unknown

    setLastActive: (active) ->
        return if @lastActive == active
        @lastActive = active
        updated 'connection'

merge exp, STATE
