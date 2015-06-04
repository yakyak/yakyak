conv = require './conv'

merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t

STATES =
    STATE_STARTUP: 'startup'
    STATE_NORMAL: 'normal'

module.exports = exp = {
    state: null
    atbottom: true # tells whether message list is scrolled to bottom
    selectedConv: localStorage.selectedConv
    focus: null
    lastActivity: null
    leftSize: localStorage.leftSize ? 200

    setState: (state) ->
        return if @state == state
        @state = state
        updated 'viewstate'

    setSelectedConv: (conv) ->
        conv = conv?.conversation_id?.id ? conv.id ? conv
        return if @selectedConv == conv
        @selectedConv = localStorage.selectedConv = conv
        updated 'viewstate'

    setFocus: (focus) ->
        return if focus == @focus
        @focus = focus
        @updateActivity(Date.now()) if focus

    updateAtBottom: (atbottom) ->
        return if @atbottom == atbottom
        @atbottom = atbottom
        @updateActivity Date.now()

    updateActivity: (time) ->
        @lastActivity = time
        updated 'lastActivity'
        return unless @focus
        c = conv[@selectedConv]
        return unless c
        ur = conv.unread c
        updated 'watermark' if ur > 0

    setLeftSize: (size) ->
        return if @leftSize == size
        @leftSize = localStorage.leftSize = size
        updated 'viewstate'

}

merge exp, STATES
