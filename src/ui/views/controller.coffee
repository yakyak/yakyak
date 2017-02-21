remote = require('electron').remote

{applayout, convlist, listhead, messages, convhead, input, conninfo, convadd, controls,
notifications, typinginfo, menu, trayicon, dockicon, startup, about} = require './index'

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
            later -> action 'lastActivity'
            el?.hide?()
            el = null
        else if viewstate.state != viewstate.STATE_STARTUP
            el = notr {html:conninfo.el.innerHTML, stay:0, id:'conn'}
        else
            # update startup with connection information
            redraw()

setLeftSize = (left) ->
    document.querySelector('.left').style.width = left + 'px'
    document.querySelector('.leftresize').style.left = (left - 2) + 'px'

setConvMin = (convmin) ->
    if convmin
        document.querySelector('.left').classList.add("minimal")
        document.querySelector('.leftresize').classList.add("minimal")
    else
        document.querySelector('.left').classList.remove("minimal")
        document.querySelector('.leftresize').classList.remove("minimal")


# remove startup from applayout after animations finishes
handle 'remove_startup', ->
    models.viewstate.startupScreenVisible = false
    redraw()

handle 'update:viewstate', ->
    setLeftSize viewstate.leftSize
    setConvMin viewstate.showConvMin
    if viewstate.state == viewstate.STATE_STARTUP
        if Array.isArray viewstate.size
            later -> remote.getCurrentWindow().setSize viewstate.size...
        if Array.isArray viewstate.pos
            {width, height} = remote.screen.getPrimaryDisplay().workAreaSize
            width = parseInt(Math.min(width * 0.9, viewstate.pos[0]), 10)
            height = parseInt(Math.min(height * 0.9, viewstate.pos[1]), 10)
            later -> remote.getCurrentWindow().setPosition(width, height)

        # only render startup
        startup(models)

        applayout.left null
        applayout.convhead null
        applayout.main null
        applayout.maininfo null
        applayout.foot null
        applayout.last startup

        document.body.style.zoom = viewstate.zoom
        document.body.style.setProperty('--zoom', viewstate.zoom)
    else if viewstate.state == viewstate.STATE_NORMAL
        redraw()
        applayout.lfoot controls
        applayout.listhead listhead
        applayout.left convlist
        applayout.convhead convhead
        applayout.main messages
        applayout.maininfo typinginfo
        applayout.foot input

        if viewstate.startupScreenVisible
            applayout.last startup
        else
            applayout.last null

        menu viewstate
        dockicon viewstate
        trayicon models

    else if viewstate.state == viewstate.STATE_ABOUT
        redraw()
        about models
        applayout.left convlist
        applayout.main about
        applayout.convhead null
        applayout.maininfo null
        applayout.foot null
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

handle 'update:conv_count', ->
    dockicon viewstate
    trayicon models

handle 'update:searchedentities', ->
  redraw()

handle 'update:selectedEntities', ->
  redraw()

handle 'update:convsettings', -> redraw()

redraw = ->
    notifications models
    convhead models
    controls models
    convlist models
    listhead models
    messages models
    typinginfo models
    input models
    convadd models
    startup models


handle 'update:language', ->
    menu viewstate
    redraw()

throttle = (fn, time=10) ->
    timeout = false
    # return a throttled version of fn
    # which executes on the trailing end of `time`
    throttled = ->
        return if timeout
        timeout = setTimeout ->
            fn()
            timeout = false
        ,
            time

redraw = throttle(redraw, 20)

handle 'update:language', ->
    menu viewstate
    redraw()

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
