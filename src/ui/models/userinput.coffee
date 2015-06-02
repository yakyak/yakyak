urlRegexp        = require 'url-regexp'
{MessageBuilder, OffTheRecordStatus} = require 'hangupsjs'

viewstate = require './viewstate'

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
        urls = urlRegexp.match line
        for url in urls
            [before, after] = split_first line, url
            if before then mb.text(before)
            line = after
            mb.link url, url
        mb.text line if line
        mb.linebreak() unless index is last
    null

buildChatMessage = (txt) ->
    conv_id = viewstate.selectedConv
    mb = new MessageBuilder()
    parse mb, txt
    segs  = mb.toSegments()
    segsj = mb.toSegsjson()
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
    }

module.exports = {
    buildChatMessage
    parse
}
