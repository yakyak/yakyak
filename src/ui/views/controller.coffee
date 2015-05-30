{applayout, convlist, messages} = require './index'

models      = require '../models'
{viewstate} = models

handle 'update:viewstate', ->
    if viewstate.state == viewstate.STATE_NORMAL
        redraw()
        applayout.left convlist
        applayout.main messages
    else
        console.log 'unknown viewstate.state', viewstate.state

handle 'update:entity', ->
    redraw()

handle 'update:conv',   ->
    redraw()

redraw = ->
    convlist models
    messages models
