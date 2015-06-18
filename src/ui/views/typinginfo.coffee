{scrollToBottom} = require './messages'
{nameof}  = require '../util'

module.exports = view (models) ->
    {viewstate, conv, entity} = models

    conv_id = viewstate?.selectedConv
    c = conv[conv_id]
    return unless c

    if c.typing?.length
        div class:'typing', ->
            for t, i in c.typing
                name = nameof entity[t.user_id.chat_id]
                span class:"typing_#{t.status}", name
                pass ', ' if i < (c.typing.length - 1)
            pass ' is typing'
    else
        div()
