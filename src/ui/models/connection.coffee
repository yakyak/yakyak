
{tryparse, later} = require '../util'

STATE =
    CONNECTING:     'connecting'     # exactly match corresponding event name
    CONNECTED:      'connected'      # exactly match corresponding event name
    CONNECT_FAILED: 'connect_failed' # exactly match corresponding event name

merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t

info =
    connecting:     'Connecting…'
    connected:      'Connected'
    connect_failed: 'Not connected'
    unknown:        'Unknown'

module.exports = exp =
    state: null # current connection state
    disableLastActive: false
    lastActive: tryparse(localStorage.lastActive) ? 0 # last activity timestamp

    setState: (state) ->
        return if @state == state
        @state = state
        updated 'connection'

    infoText: -> info[@state] ? info.unknown

    setLastActive: (active, force) ->
        return if @disableLastActive
        return if @lastActive == active
        timegap = active - @lastActive
        if not force and timegap > 10 * 60 * 1000
            # if we have a gap of more than 10 minutes, we will
            # reinitialize all convs using syncrecentconversations
            # (sort of like client startup)
            later -> action 'syncrecentconversations'
        else if not force and timegap > 40000
            # if we have a gap of more than 40 seconds we try getting
            # any events we may have missed during that gap. notice
            # that we get 'noop' every 20-30 seconds, so there is no
            # reason for a gap of 40 seconds.
            later -> action 'syncallnewevents', @lastActive
        else
            @lastActive = localStorage.lastActive = active
        updated 'connection'

    setDisableLastActive: (dis) -> @disableLastActive = dis

merge exp, STATE
