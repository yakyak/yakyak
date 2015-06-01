{applayout, convlist, messages, input} = require './index'

models      = require '../models'
{viewstate} = models

handle 'update:viewstate', ->
    if viewstate.state == viewstate.STATE_NORMAL
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
