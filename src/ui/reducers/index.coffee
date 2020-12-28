
reducer = (state, action) ->
    switch action.type
        when '' then state # one case is necessary
        else state

module.exports = reducer
