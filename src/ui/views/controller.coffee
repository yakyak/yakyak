ipc = require('electron').ipcRenderer

{
  applayout, convlist, listhead, messages, convhead, input, conninfo,
  convadd, controls, notifications, typinginfo, menu, trayicon, dockicon,
  startup, about
} = require './index'

models = require '../models'

{ viewstate, connection } = models

{ later } = require '../util'

#                                    _   _
#                                   | | (_)
#     ___ ___  _ __  _ __   ___  ___| |_ _  ___  _ __
#    / __/ _ \| '_ \| '_ \ / _ \/ __| __| |/ _ \| '_ \
#   | (_| (_) | | | | | | |  __/ (__| |_| | (_) | | | |
#    \___\___/|_| |_|_| |_|\___|\___|\__|_|\___/|_| |_|
#
#
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
        else if not viewstate.loggedin
            el = notr {html:conninfo.el.innerHTML, stay:0, id:'conn'}
        else
            # update startup with connection information
            redraw()

#          _                   _        _
#         (_)                 | |      | |
#   __   ___  _____      _____| |_ __ _| |_ ___
#   \ \ / / |/ _ \ \ /\ / / __| __/ _` | __/ _ \
#    \ V /| |  __/\ V  V /\__ \ || (_| | ||  __/
#     \_/ |_|\___| \_/\_/ |___/\__\__,_|\__\___|
#
#
handle 'viewstate_updated', ->
    updated 'viewstate'

handle 'update:viewstate', ->
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

    setLeftSize viewstate.leftSize
    setConvMin viewstate.showConvMin

    # check what in what state is the app
    #
    # STATE_INITIAL : still connecting
    # STATE_NORMAL  : conversation list on left with selected chat showing in main window
    # STATE_ABOUT   : conversation list on the left with about showing in main window
    # STATE_ADD_CONVERSATION : conversation list on the left and new / modify conversation on the main window
    if viewstate.state == viewstate.STATE_INITIAL or viewstate.startup
        if Array.isArray viewstate.size
            ipc.send 'mainwindow:setsize', viewstate.size
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
            winSize = viewstate.winSize
            # iterate on all displays to see if the desired position is valid
            for screen in viewstate.allDisplays
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
            ipc.send 'mainwindow:setposition', xWindowPos, yWindowPos
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

        viewstate.startupDone()

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
        later ->
            search = document.querySelector '.search-input'
            search.focus()
    else
        console.log 'unknown viewstate.state', viewstate.state

#                 _
#                | |
#    _ __ ___  __| |_ __ __ ___      __
#   | '__/ _ \/ _` | '__/ _` \ \ /\ / /
#   | | |  __/ (_| | | | (_| |\ V  V /
#   |_|  \___|\__,_|_|  \__,_| \_/\_/
#
# simple redrawing all of yakyak UI
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

#               _   _ _
#              | | (_) |
#     ___ _ __ | |_ _| |_ _   _
#    / _ \ '_ \| __| | __| | | |
#   |  __/ | | | |_| | |_| |_| |
#    \___|_| |_|\__|_|\__|\__, |
#                          __/ |
#                         |___/
handle 'update:entity', -> redraw()

#
#
#     ___ ___  _ ____   __
#    / __/ _ \| '_ \ \ / /
#   | (_| (_) | | | \ V /
#    \___\___/|_| |_|\_/
#
#
handle 'update:conv', -> redraw()

#                                                 _
#                                                | |
#     ___ ___  _ ____   __   ___ ___  _   _ _ __ | |_
#    / __/ _ \| '_ \ \ / /  / __/ _ \| | | | '_ \| __|
#   | (_| (_) | | | \ V /  | (_| (_) | |_| | | | | |_
#    \___\___/|_| |_|\_/    \___\___/ \__,_|_| |_|\__|
#
#
handle 'update:conv_count', ->
    dockicon viewstate
    trayicon models

#                            _              _              _   _ _   _
#                           | |            | |            | | (_) | (_)
#    ___  ___  __ _ _ __ ___| |__   ___  __| |   ___ _ __ | |_ _| |_ _  ___  ___
#   / __|/ _ \/ _` | '__/ __| '_ \ / _ \/ _` |  / _ \ '_ \| __| | __| |/ _ \/ __|
#   \__ \  __/ (_| | | | (__| | | |  __/ (_| | |  __/ | | | |_| | |_| |  __/\__ \
#   |___/\___|\__,_|_|  \___|_| |_|\___|\__,_|  \___|_| |_|\__|_|\__|_|\___||___/
#
#
handle 'update:searchedentities', -> redraw()

#             _           _           _              _   _ _   _
#            | |         | |         | |            | | (_) | (_)
#    ___  ___| | ___  ___| |_ ___  __| |   ___ _ __ | |_ _| |_ _  ___  ___
#   / __|/ _ \ |/ _ \/ __| __/ _ \/ _` |  / _ \ '_ \| __| | __| |/ _ \/ __|
#   \__ \  __/ |  __/ (__| ||  __/ (_| | |  __/ | | | |_| | |_| |  __/\__ \
#   |___/\___|_|\___|\___|\__\___|\__,_|  \___|_| |_|\__|_|\__|_|\___||___/
#
#
handle 'update:selectedEntities', -> redraw()

#                                    _   _   _
#                                   | | | | (_)
#     ___ ___  _ ____   __  ___  ___| |_| |_ _ _ __   __ _ ___
#    / __/ _ \| '_ \ \ / / / __|/ _ \ __| __| | '_ \ / _` / __|
#   | (_| (_) | | | \ V /  \__ \  __/ |_| |_| | | | | (_| \__ \
#    \___\___/|_| |_|\_/   |___/\___|\__|\__|_|_| |_|\__, |___/
#                                                     __/ |
#                                                    |___/
handle 'update:convsettings', -> redraw()

#    _
#   | |
#   | | __ _ _ __   __ _ _   _  __ _  __ _  ___
#   | |/ _` | '_ \ / _` | | | |/ _` |/ _` |/ _ \
#   | | (_| | | | | (_| | |_| | (_| | (_| |  __/
#   |_|\__,_|_| |_|\__, |\__,_|\__,_|\__, |\___|
#                   __/ |             __/ |
#                  |___/             |___/
handle 'update:language', ->
    menu viewstate
    redraw()

#                 _ _       _
#                (_) |     | |
#    _____      ___| |_ ___| |__     ___ ___  _ ____   __
#   / __\ \ /\ / / | __/ __| '_ \   / __/ _ \| '_ \ \ / /
#   \__ \\ V  V /| | || (__| | | | | (_| (_) | | | \ V /
#   |___/ \_/\_/ |_|\__\___|_| |_|  \___\___/|_| |_|\_/
#
#
handle 'update:switchConv', -> messages.scrollToBottom()

#    _           __                 _     _     _
#   | |         / _|               | |   (_)   | |
#   | |__   ___| |_ ___  _ __ ___  | |__  _ ___| |_ ___  _ __ _   _
#   | '_ \ / _ \  _/ _ \| '__/ _ \ | '_ \| / __| __/ _ \| '__| | | |
#   | |_) |  __/ || (_) | | |  __/ | | | | \__ \ || (_) | |  | |_| |
#   |_.__/ \___|_| \___/|_|  \___| |_| |_|_|___/\__\___/|_|   \__, |
#                                                              __/ |
#                                                             |___/
handle 'update:beforeHistory', -> applayout.recordMainPos()

#           __ _              _     _     _
#          / _| |            | |   (_)   | |
#     __ _| |_| |_ ___ _ __  | |__  _ ___| |_ ___  _ __ _   _
#    / _` |  _| __/ _ \ '__| | '_ \| / __| __/ _ \| '__| | | |
#   | (_| | | | ||  __/ |    | | | | \__ \ || (_) | |  | |_| |
#    \__,_|_|  \__\___|_|    |_| |_|_|___/\__\___/|_|   \__, |
#                                                        __/ |
#                                                       |___/
handle 'update:afterHistory', -> applayout.adjustMainPos()

#    _           __                 _
#   | |         / _|               (_)
#   | |__   ___| |_ ___  _ __ ___   _ _ __ ___   __ _
#   | '_ \ / _ \  _/ _ \| '__/ _ \ | | '_ ` _ \ / _` |
#   | |_) |  __/ || (_) | | |  __/ | | | | | | | (_| |
#   |_.__/ \___|_| \___/|_|  \___| |_|_| |_| |_|\__, |
#                                                __/ |
#                                               |___/
handle 'update:beforeImg', -> applayout.recordMainPos()

#           __ _              _
#          / _| |            (_)
#     __ _| |_| |_ ___ _ __   _ _ __ ___   __ _
#    / _` |  _| __/ _ \ '__| | | '_ ` _ \ / _` |
#   | (_| | | | ||  __/ |    | | | | | | | (_| |
#    \__,_|_|  \__\___|_|    |_|_| |_| |_|\__, |
#                                          __/ |
#                                         |___/
handle 'update:afterImg', ->
    if viewstate.atbottom
        messages.scrollToBottom()
    else
        applayout.adjustMainPos()

#        _             _     _               _
#       | |           | |   | |             (_)
#    ___| |_ __ _ _ __| |_  | |_ _   _ _ __  _ _ __   __ _
#   / __| __/ _` | '__| __| | __| | | | '_ \| | '_ \ / _` |
#   \__ \ || (_| | |  | |_  | |_| |_| | |_) | | | | | (_| |
#   |___/\__\__,_|_|   \__|  \__|\__, | .__/|_|_| |_|\__, |
#                                 __/ | |             __/ |
#                                |___/|_|            |___/
handle 'update:startTyping', ->
    if viewstate.atbottom
        messages.scrollToBottom()
