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

handle 'update:viewstate', ->
    setLeftSize viewstate.leftSize
    setConvMin viewstate.showConvMin
    if viewstate.state == viewstate.STATE_STARTUP
        if Array.isArray viewstate.size
            later -> remote.getCurrentWindow().setSize viewstate.size...
        #
        #
        # It will not allow the window to be placed offscreen (fully or partial)
        #
        # For that it needs to iterate on all screens and see if position is valid.
        #  If it is not valid, then it will approximate the best position possible
        if Array.isArray viewstate.pos
            # uses max X and Y as a fallback method in case it can't be placed on any
            #  current display, by approximating a new position
            maxX = maxY = maxW = maxH = 0
            reposition = false
            # helper variable to determine valid coordinates to be used, initialized with
            #  desired coordinates
            xWindowPos = viewstate.pos[0]
            yWindowPos = viewstate.pos[1]
            # window size to be used in rounding the position, i.e. avoiding partial offscreen
            winSize = remote.getCurrentWindow().getSize()
            # iterate on all displays to see if the desired position is valid
            for screen in remote.screen.getAllDisplays()
                # get bounds of each display
                {width, height} = screen.workAreaSize
                {x, y} = screen.workArea

                # see if this improves on maxY and maxX
                if x + width > maxW
                    maxX = x
                    maxW = x + width
                if y + height > maxH
                    maxY = y
                    maxH = y + height


                # check if window will be placed in this display
                if xWindowPos >= x and xWindowPos < x + width and yWindowPos >= y and yWindowPos < y + height
                    # if window will be partially placed outside of this display, then it will
                    #  move it all inside the display

                    # for X
                    if winSize[0] > width
                        xWindowPos = x
                    else if xWindowPos > x + width - winSize[0] / 2
                        xWindowPos = x + width - winSize[0] / 2

                    # for Y
                    if winSize[1] > height
                        yWindowPos = y
                    else if yWindowPos > y + width - winSize[1] / 2
                        yWindowPos = y + width - winSize[1] / 2
                    # making sure no negative positions on displays
                    xWindowPos = Math.max(xWindowPos, x)
                    yWindowPos = Math.max(yWindowPos, y)
                    #
                    reposition = true # coordinates have been calculated
                    break # break the loop
            if not reposition
                xWindowPos = maxW - winSize[0] if xWindowPos > maxW
                yWindowPos = maxY if yWindowPos > maxH
                xWindowPos = Math.max(xWindowPos, maxX)
                yWindowPos = Math.max(yWindowPos, maxY)
            later -> remote.getCurrentWindow().setPosition(xWindowPos, yWindowPos)
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
