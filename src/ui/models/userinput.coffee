urlRegexp = require 'uber-url-regex'
{MessageBuilder, OffTheRecordStatus,MessageActionType,ClientDeliveryMediumType} = require 'hangupsjs'
viewstate = require './viewstate'
conv = require './conv'

randomid = -> Math.round Math.random() * Math.pow(2,32)

split_first = (str, token) ->
  start = str.indexOf token
  first = str.substr 0, start
  last = str.substr start + token.length
  [first, last]

parse = (mb, txt) ->
    lines = txt.split /\r?\n/
    last = lines.length - 1
    for line, index in lines
        urls = line.match urlRegexp()
        if urls?
            for url in urls
                [before, after] = split_first line, url
                if before then mb.text(before)
                line = after
                mb.link url, url
        mb.text line if line
        mb.linebreak() unless index is last
    null

buildChatMessage = (sender, txt) ->
    conv_id = viewstate.selectedConv
    conversation_state = conv[conv_id]?.self_conversation_state
    delivery_medium = ClientDeliveryMediumType[conversation_state?.delivery_medium_option[0]?.delivery_medium?.delivery_medium_type]
    if not delivery_medium
      delivery_medium = ClientDeliveryMediumType.BABEL
    action = null
    if /^\/me\s/.test txt
        txt = txt.replace /^\/me/, sender.first_name
        action = MessageActionType.ME_ACTION
    mb = new MessageBuilder(action)
    parse mb, txt
    segs  = mb.toSegments()
    segsj = mb.toSegsjson()
    message_action_type = mb.toMessageActionType()
    client_generated_id = String randomid()
    ts = Date.now()
    {
        segs
        segsj
        conv_id
        client_generated_id
        ts
        image_id: undefined
        otr: OffTheRecordStatus.ON_THE_RECORD
        message_action_type
        delivery_medium: [delivery_medium] # requires to be used as an array
    }

module.exports = {
    buildChatMessage
    parse
}
