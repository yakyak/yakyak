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

recursiveOut = (mb, node,bold, italic, strike, underline,link)->

        if node.nodeType==3
            line = node.data
            urls = line.match urlRegexp()
            if urls?
                for url in urls
                    [before, after] = split_first line, url
                    if before then mb.text(before, bold, italic,strike, underline)
                    line = after
                    mb.link url, url
            mb.text line, bold, italic,strike, underline if line
        else
            switch node.nodeName
                when 'B' then  bold=true
                when 'I' then  italic=true
                when 'U' then  underline=true
                when 'S' then  strike=true
                when 'BR' then mb.linebreak()
            if node.childNodes
                for childNode in node.childNodes
                    recursiveOut(mb, childNode,bold, italic, strike, underline)
            

parse = (mb, txt) ->
    #lines = txt.split /\r?\n/
    ##lines = txt.split "<br>"
    ##last = lines.length - 1
    ##for line, index in lines
    tmpDiv = document.createElement('div')
    tmpDiv.innerHTML = txt
    bold = false
    italic = false
    strike = false
    underline = false
    recursiveOut(mb,tmpDiv,bold, italic, strike, underline)
    #mb.linebreak() unless index is last
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
