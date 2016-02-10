Client = require 'hangupsjs'

merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t

{throttle, later, tryparse} = require '../util'

STATES =
    STATE_STARTUP: 'startup'
    STATE_NORMAL: 'normal'
    STATE_ADD_CONVERSATION: 'add_conversation'

module.exports = exp = {
    state: null
    attop: false   # tells whether message list is scrolle to top
    atbottom: true # tells whether message list is scrolled to bottom
    selectedConv: localStorage.selectedConv
    lastActivity: null
    leftSize: tryparse(localStorage.leftSize) ? 200
    size: tryparse(localStorage.size ? "[940, 600]")
    pos: tryparse(localStorage.pos ? "[100, 100]")
    showConvThumbs: tryparse(localStorage.showConvThumbs)
    zoom: tryparse(localStorage.zoom ? "1.0")
    loggedin: false
    showtray: tryparse(localStorage.showtray) or false
    hidedockicon: tryparse(localStorage.hidedockicon) or false
    startminimizedtotray: tryparse(localStorage.startminimizedtotray) or false

    setState: (state) ->
        return if @state == state
        @state = state
        if state == STATES.STATE_STARTUP
            # set a first active timestamp to avoid requesting
            # syncallnewevents on startup
            require('./connection').setLastActive(Date.now(), true)
        updated 'viewstate'

    setSelectedConv: (c) ->
        conv = require './conv' # circular
        conv_id = c?.conversation_id?.id ? c?.id ? c
        unless conv_id
            conv_id = conv.list()?[0]?.conversation_id?.id
        return if @selectedConv == conv_id
        @selectedConv = localStorage.selectedConv = conv_id
        @setLastKeyDown 0
        updated 'viewstate'
        updated 'switchConv'

    selectNextConv: (offset = 1) ->
        conv = require './conv'
        id = @selectedConv
        c = conv[id]
        list = (i for i in conv.list() when not conv.isPureHangout(i))
        for c, index in list
            if id == c.conversation_id.id
                candidate = index + offset
                @setSelectedConv list[candidate] if list[candidate]

    updateAtTop: (attop) ->
        return if @attop == attop
        @attop = attop
        updated 'viewstate'

    updateAtBottom: (atbottom) ->
        return if @atbottom == atbottom
        @atbottom = atbottom
        @updateActivity Date.now()

    updateActivity: (time) ->
        conv = require './conv' # circular
        @lastActivity = time
        later -> action 'lastActivity'
        return unless document.hasFocus() and @atbottom and @state == STATES.STATE_NORMAL
        c = conv[@selectedConv]
        return unless c
        ur = conv.unread c
        if ur > 0
            later -> action 'updatewatermark'

    setSize: (size) ->
        localStorage.size = JSON.stringify(size)
        @size = size
        updated 'viewstate'

    setPosition: (pos) ->
        localStorage.pos = JSON.stringify(pos)
        @pos = pos
        updated 'viewstate'

    setLeftSize: (size) ->
        return if @leftSize == size
        @leftSize = localStorage.leftSize = size
        updated 'viewstate'

    setZoom: (zoom) ->
        @zoom = localStorage.zoom = document.body.style.zoom = zoom

    setLoggedin: (val) ->
        @loggedin = val
        updated 'viewstate'

    setLastKeyDown: do ->
        {TYPING, PAUSED, STOPPED} = Client.TypingStatus
        lastEmitted = 0
        timeout = 0
        update = throttle 500, (time) ->
            clearTimeout timeout if timeout
            timeout = null
            unless time
                lastEmitted = 0
            else
                if time - lastEmitted > 5000
                    later -> action 'settyping', TYPING
                    lastEmitted = time
                timeout = setTimeout ->
                    # after 6 secods of no keyboard, we consider the
                    # user took a break.
                    lastEmitted = 0
                    action 'settyping', PAUSED
                    timeout = setTimeout ->
                        # and after another 6 seconds (12 total), we
                        # consider the typing stopped altogether.
                        action 'settyping', STOPPED
                    , 6000
                , 6000

    setShowConvThumbs: (doshow) ->
        return if @showConvThumbs == doshow
        @showConvThumbs = localStorage.showConvThumbs = doshow
        updated 'viewstate'

    setShowTray: (value) ->
        @showtray = localStorage.showtray = value
        if not value then @setStartMinimizedToTray(false) else updated 'viewstate'
      
    setHideDockIcon: (value) ->
        @hidedockicon = localStorage.hidedockicon = value
        updated 'viewstate'
    
    setStartMinimizedToTray: (value) ->
        @startminimizedtotray = localStorage.startminimizedtotray = value
        updated 'viewstate'
      

}

merge exp, STATES
