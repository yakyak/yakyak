autosize = require 'autosize'

{later} = require './vutil'

module.exports = view (models) ->
    div class:'input', -> div ->
        textarea autofocus:true, placeholder:'Message', rows: 1, ''
        , onDOMNodeInserted: (e) ->
            # at this point the node is still not inserted
            ta = e.target
            later -> autosize ta
