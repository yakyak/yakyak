{applayout, convlist, messages, input, conninfo} = require './index'

models      = require '../models'
{viewstate, connection} = models

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
        applayout.left null
        applayout.main null
        applayout.foot null
    else if viewstate.state == viewstate.STATE_NORMAL
        redraw()
        applayout.left convlist
        applayout.main messages
        applayout.foot input
    else
        console.log 'unknown viewstate.state', viewstate.state

handle 'update:entity', ->
    redraw()

handle 'update:conv',   ->
    redraw()

redraw = ->
    convlist models
    messages models
    input models
