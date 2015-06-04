
STATE =
    CONNECTING:     'connecting'     # exactly match corresponding event name
    CONNECTED:      'connected'      # exactly match corresponding event name
    CONNECT_FAILED: 'connect_failed' # exactly match corresponding event name

module.exports =
    state: null     # current connection state
    lastActive: null  # last activity timestamp

    setState: (state) ->
        return if @state == state
        @state = state
        updated 'connection'

    setLastActive: (active) ->
        return if @lastActive == active
        @lastActive = active
        updated 'connection'
