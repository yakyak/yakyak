{nameof, nameofconv, later, tryparse}  = require '../util'

sortby = (conv) -> conv?.self_conversation_state?.sort_timestamp ? 0

module.exports =
    # this number correlates to number of max events we get from
    # hangouts on client startup
    MAX_UNREAD: 20
    # the number of history events to request
    HISTORY_AMOUNT: 20
    count: (state) ->
        lookup = state.conversations
        #
        c = 0; (c++ for k, v of lookup when typeof v == 'object'); c

    findLastReadEventsByUser: (conv) ->
        last_seen_events_by_user = {}
        for contact in conv.read_state
            chat_id = contact.participant_id.chat_id
            last_read = contact.last_read_timestamp ? contact.latest_read_timestamp
            for e in conv.event ? [] when e.timestamp <= last_read
                last_seen_events_by_user[chat_id] = e
        last_seen_events_by_user

    # a "hangout" is in google terms strictly an audio/video event
    # many conversations in the conversation list are just such an
    # event with no further chat messages or activity. this function
    # tells whether a hangout only contains video/audio.
    isPureHangout: (c)->
        isEventType = (type) -> (ev) -> !!ev[type]
        nots = ['chat_message', 'conversation_rename'].map(isEventType)
        isNotHangout = (e) -> nots.some (f) -> f(e)
        not (c?.event ? []).some isNotHangout

    isQuiet: (c) -> c?.self_conversation_state?.notification_level == 'QUIET'

    isStarred: (c) -> return c?.conversation_id?.id in @starredconvs()

    # the time of the last added event
    lastChanged: (c) -> (c?.event?[(c?.event?.length ? 0) - 1]?.timestamp ? 0) / 1000

    list: (state, sort = true) ->
        lookup = state.conversations
        #
        convs = (v for k, v of lookup when typeof v == 'object')
        if sort
            starred = (c for c in convs when @isStarred(c))
            convs = (c for c in convs when not @isStarred(c))
            starred.sort (e1, e2) -> nameofconv(e1).localeCompare(nameofconv(e2))
            convs.sort (e1, e2) -> sortby(e2) - sortby(e1)
            return starred.concat convs
        convs

    redraw_conversation: () ->
        # first signal is to give views a change to record the
        # current view position before injecting new DOM
        updated 'beforeHistory'
        # redraw
        updated 'conv'
        # last signal is to move view to be at same place
        # as when we injected DOM.
        updated 'afterHistory'

    starredconvs: -> tryparse(localStorage.starredconvs) || []

    unread: (state, conv) ->
        {entity} = state
        #
        t = conv?.self_conversation_state?.self_read_state?.latest_read_timestamp
        return 0 unless typeof t == 'number'
        c = 0
        for e in conv?.event ? []
            c++ if e.chat_message and e.timestamp > t and not entity.isSelf e.sender_id.chat_id
            return @MAX_UNREAD if c >= @MAX_UNREAD
        c

    unreadTotal: do ->
        current = 0
        orMore = false
        ->
            sum = (a, b) -> return a + b
            orMore = false
            countunread = (c) ->
                if @isQuiet(c) then return 0
                count = @unread c
                if count == @MAX_UNREAD then orMore = true
                return count
            newTotal = @list(false).map(countunread).reduce(sum, 0)
            if current != newTotal
                current = newTotal
                later -> action 'unreadtotal', newTotal, orMore
            return newTotal
