
merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t

STATES =
    STATE_NORMAL = 'normal'

module.exports = exp = {
    state: null
    selectedConv: null

    setState: (state) ->
        return if @state == state
        @state = state
        updated 'viewstate'

    setSelectedConv: (conv) ->
        conv = conv?.conversation_id?.id ? conv.id ? conv
        return if @selectedConv == conv
        @selectedConv = conv
        updated 'viewstate'
}

merge exp, STATES
