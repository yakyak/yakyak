remote = require 'remote'

{applayout, convlist, messages, input, conninfo, convadd, controls,
notifications, typinginfo, menu, trayicon, dockicon } = require './index'

models      = require '../models'
{viewstate, connection} = models

{later} = require '../util'


handle 'update:connection', do ->
    el = null
    ->
        # draw view
        conninfo connection

        # place in layout
        if connection.state == connection.CONNECTED
            el?.hide?()
            el = null
        else
            el = notr {html:conninfo.el.innerHTML, stay:0, id:'conn'}


setLeftSize = (left) ->
    document.querySelector('.left').style.width = left + 'px'
    document.querySelector('.leftresize').style.left = (left - 2) + 'px'


handle 'update:viewstate', ->
    setLeftSize viewstate.leftSize
    if viewstate.state == viewstate.STATE_STARTUP
        if Array.isArray viewstate.size
            later -> remote.getCurrentWindow().setSize viewstate.size...
        if Array.isArray viewstate.pos
            later -> remote.getCurrentWindow().setPosition viewstate.pos...
        applayout.left null
        applayout.main null
        applayout.maininfo null
        applayout.foot null
        document.body.style.zoom = viewstate.zoom
    else if viewstate.state == viewstate.STATE_NORMAL
        redraw()
        applayout.lfoot controls
        applayout.left convlist
        applayout.main messages
        applayout.maininfo typinginfo
        applayout.foot input
        menu viewstate
        trayicon models
        dockicon viewstate
    else if viewstate.state == viewstate.STATE_ADD_CONVERSATION
        redraw()
        applayout.left convlist
        applayout.main convadd
        applayout.maininfo null
        applayout.foot null
    else
        console.log 'unknown viewstate.state', viewstate.state

handle 'update:entity', ->
    redraw()

handle 'update:conv', ->
    redraw()

handle 'update:searchedentities', ->
  redraw()

handle 'update:selectedEntities', ->
  redraw()

handle 'update:convsettings', -> redraw()

redraw = ->
    notifications models
    controls models
    convlist models
    messages models
    typinginfo models
    input models
    convadd models
    trayicon models

handle 'update:switchConv', ->
    messages.scrollToBottom()

handle 'update:beforeHistory', ->
    applayout.recordMainPos()
handle 'update:afterHistory', ->
    applayout.adjustMainPos()

handle 'update:beforeImg', ->
    applayout.recordMainPos()
handle 'update:afterImg', ->
    if viewstate.atbottom
        messages.scrollToBottom()
    else
        applayout.adjustMainPos()

handle 'update:startTyping', ->
    if viewstate.atbottom
        messages.scrollToBottom()
