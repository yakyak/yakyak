
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
        conv = conv.id if conv
        return if @selectedConv == conv
        @selectedConv = conv
        updated 'viewstate'
}

merge exp, STATES
