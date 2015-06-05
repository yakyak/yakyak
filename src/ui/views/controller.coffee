remote = require 'remote'

{applayout, convlist, messages, input, conninfo, convadd, controls} = require './index'

models      = require '../models'
{viewstate, connection} = models

{later} = require './vutil'

showInfo = (view) ->
    applayout.info view
hideInfo = ->
    applayout.info null


handle 'update:connection', ->
    # draw view
    conninfo connection

    # place in layout
    if connection.state == connection.CONNECTED
        hideInfo()
    else
        showInfo conninfo


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
        applayout.foot null
    else if viewstate.state == viewstate.STATE_NORMAL
        redraw()
        applayout.lfoot controls
        applayout.left convlist
        applayout.main messages
        applayout.foot input
    else if viewstate.state == viewstate.STATE_ADD_CONVERSATION
        redraw()
        applayout.left convlist
        applayout.main convadd
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

redraw = ->
    controls models
    convlist models
    messages models
    input models
    convadd models
