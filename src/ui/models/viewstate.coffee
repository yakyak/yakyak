
merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t

STATES =
    STATE_STARTUP: 'startup'
    STATE_NORMAL: 'normal'
    STATE_ADD_CONVERSATION: 'add_conversation'

module.exports = exp = {
    state: null
    atbottom: true # tells whether message list is scrolled to bottom
    selectedConv: localStorage.selectedConv
    lastActivity: null
    leftSize: localStorage.leftSize ? 200
    size: JSON.parse(localStorage.size ? "[940, 600]")
    pos: JSON.parse(localStorage.pos ? "[100, 100]")

    setState: (state) ->
        return if @state == state
        @state = state
        updated 'viewstate'

    setSelectedConv: (c) ->
        conv = require './conv' # circular
        conv_id = c?.conversation_id?.id ? c?.id ? c
        unless conv_id
            conv_id = conv.list()?[0]?.conversation_id?.id
        return if @selectedConv == conv_id
        @selectedConv = localStorage.selectedConv = conv_id
        updated 'viewstate'

    updateAtBottom: (atbottom) ->
        return if @atbottom == atbottom
        @atbottom = atbottom
        @updateActivity Date.now()

    updateActivity: (time) ->
        conv = require './conv' # circular
        @lastActivity = time
        updated 'lastActivity'
        return unless document.hasFocus() and @atbottom and @state == STATES.STATE_NORMAL
        c = conv[@selectedConv]
        return unless c
        ur = conv.unread c
        updated 'watermark' if ur > 0

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

}

merge exp, STATES
