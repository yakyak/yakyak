ipc = require 'ipc'
urlRegexp = require 'url-regexp'
normalizeUrl = require 'normalize-url'
{entity, conv, viewstate} = require './models'
{MessageBuilder} = require 'hangupsjs'

{throttle} = require './views/vutil'

module.exports =
    init: ({init, recorded}) ->
        action 'init', init
        action n, e for [n, e] in recorded


handle 'init', (init) ->
    # set the initial view state
    viewstate.setState viewstate.STATE_NORMAL
    # update model from init object
    entity._initFromSelfEntity init.self_entity
    entity._initFromEntities init.entities
    conv._initFromConvStates init.conv_states
    # ensure there's a selected conv
    unless viewstate.selectedConv
        viewstate.setSelectedConv conv.list()?[0]?.conversation_id


handle 'chat_message', (ev) ->
    conv.addChatMessage ev


handle 'watermark', (ev) ->
    conv.addWatermark ev

handle 'focus', ->
    viewstate.setFocus true

handle 'blur', ->
    viewstate.setFocus false

handle 'activity', (time) ->
    viewstate.updateActivity time

handle 'atbottom', (atbottom) ->
    viewstate.updateAtBottom atbottom

handle 'selectConv', (conv) -> viewstate.setSelectedConv conv

split_first = (str, token) ->
  start = str.indexOf token
  first = str.substr 0, start
  last = str.substr start + token.length
  [first, last]

# XXX too much logic here. refactor to make
# an input parser that builds an object with all
# params passed to server.
randomid = -> Math.round Math.random() * Math.pow(2,32)
handle 'sendmessage', (txt) ->
    conv_id = viewstate.selectedConv
    mb = new MessageBuilder()
    lines = txt.split '\n'
    last = lines.length - 1
    for index, line of lines
      urls = urlRegexp.match line
      for url in urls
        [before, after] = split_first line, url
        if before then mb.text(before)
        line = after
        mb.link (normalizeUrl url), url
      mb.text line
      mb.linebreak() unless index is last
    segs = mb.toSegments()
    client_generated_id = randomid() + ''
    ipc.send 'sendchatmessage', conv_id, segs, client_generated_id
    conv.addChatMessagePlaceholder conv_id, entity.self.id,
        client_generated_id, mb.toSegsjson()

sendSetPresence = throttle 10000, -> ipc.send 'setpresence'

handle 'update:lastActivity', -> sendSetPresence()

throttleWaterByConv = {
}

handle 'update:watermark', ->
    conv_id = viewstate.selectedConv
    c = conv[conv_id]
    return unless c
    sendWater = throttleWaterByConv[conv_id]
    unless sendWater
        do (conv_id) ->
            sendWater = throttle 2000, -> ipc.send 'updatewatermark', conv_id, Date.now()
            throttleWaterByConv[conv_id] = sendWater
    sendWater()
