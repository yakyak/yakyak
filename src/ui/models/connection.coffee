
{tryparse, later} = require '../util'

STATE =
    CONNECTING:     'connecting'     # exactly match corresponding event name
    CONNECTED:      'connected'      # exactly match corresponding event name
    CONNECT_FAILED: 'connect_failed' # exactly match corresponding event name

EVENT_STATE =
    IN_SYNC:         'in_sync'       # when we certain we have connection/events
    MISSING_SOME:    'missing_some'  # when more than 40 secs without any event
    MISSING_ALL:     'missing_all'   # when more than 10 minutes without any event

TIME_SOME = 40 * 1000      # 40 secs
TIME_ALL  = 10 * 60 * 1000 # 10 mins

info =
    connecting:     'Connecting…'
    connected:      'Connected'
    connect_failed: 'Not connected'
    unknown:        'Unknown'

module.exports = exp =
    state: null       # current connection state
    eventState: null  # current event state
    lastActive: tryparse(localStorage.lastActive) ? 0 # last activity timestamp
    wasConnected: false

    setState: (state) ->
        return if @state == state
        @state = state
        if @wasConnected and state == STATE.CONNECTED
            later -> action 'syncrecentconversations'
        @wasConnected = @wasConnected or state == STATE.CONNECTED
        updated 'connection'

    setWindowOnline: (wonline) ->
        return if @wonline == wonline
        @wonline = wonline
        unless @wonline
            @setState STATE.CONNECT_FAILED

    infoText: -> info[@state] ? info.unknown

    setLastActive: (active) ->
        return if @lastActive == active
        @lastActive = localStorage.lastActive = active

    setEventState: (state) ->
        return if @eventState == state
        @eventState = state
        if state == EVENT_STATE.IN_SYNC
            @setLastActive Date.now() unless @lastActive
        else if state == EVENT_STATE.MISSING_SOME
            # if we have a gap of more than 40 seconds we try getting
            # any events we may have missed during that gap. notice
            # that we get 'noop' every 20-30 seconds, so there is no
            # reason for a gap of 40 seconds.
            later -> action 'syncallnewevents', @lastActive
        else if state == EVENT_STATE.MISSING_ALL
            # if we have a gap of more than 10 minutes, we will
            # reinitialize all convs using syncrecentconversations
            # (sort of like client startup)
            later -> action 'syncrecentconversations'
        later -> checkEventState()
        updated 'connection'

Object.assign exp, STATE
Object.assign exp, EVENT_STATE

checkTimer = null
checkEventState = ->
    elapsed = Date.now() - exp.lastActive
    clearTimeout checkTimer if checkTimer
    if elapsed >= TIME_ALL
        wrapAction -> exp.setEventState EVENT_STATE.MISSING_ALL
    else if elapsed >= TIME_SOME
        wrapAction -> exp.setEventState EVENT_STATE.MISSING_SOME
    else
        wrapAction -> exp.setEventState EVENT_STATE.IN_SYNC
    checkTimer = setTimeout checkEventState, 1000

wrapAction = (f) ->
    handle 'connwrap', -> f()
    action 'connwrap'
