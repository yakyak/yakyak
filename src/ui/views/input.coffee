autosize = require 'autosize'

{later} = require './vutil'

isModifierKey = (ev) -> ev.ctrlKey || ev.metaKey || ev.shiftKey

module.exports = view (models) ->
    div class:'input', -> div ->
        textarea autofocus:true, placeholder:'Message', rows: 1, ''
        , onDOMNodeInserted: (e) ->
            # at this point the node is still not inserted
            ta = e.target
            later -> autosize ta
        , onkeydown: (e) ->
            return if isModifierKey e
            if e.keyCode == 13
                e.preventDefault()
                e.stopPropagation()
                action 'sendmessage', e.target.value
                e.target.value = ''
