conv = require './conv'

merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t

STATES =
    STATE_NORMAL = 'normal'

module.exports = exp = {
    state: null
    selectedConv: null
    focus: null
    lastActivity: null

    setState: (state) ->
        return if @state == state
        @state = state
        updated 'viewstate'

    setSelectedConv: (conv) ->
        conv = conv?.conversation_id?.id ? conv.id ? conv
        return if @selectedConv == conv
        @selectedConv = conv
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
        c = conv[@selectedConv]
        return unless c
        ur = conv.unread c
        if ur > 0
            updated 'watermark'


}

merge exp, STATES
