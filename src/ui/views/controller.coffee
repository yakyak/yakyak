remote = require('electron').remote

{applayout, convlist, listhead, messages, convhead, input, conninfo, convadd, controls,
notifications, typinginfo, menu, trayicon, dockicon } = require './index'

models      = require '../models'
{viewstate, connection} = models

{later} = require '../util'


handle 'update:connection', do ->
    el = null
    ->
        # draw view
        conninfo connection

        startupConnEl = document.querySelector('.state_connecting')
        startupLoadEl = document.querySelector('.state_contacts')
        # place in layout
        if connection.state == connection.CONNECTED
            el?.hide?()
            startupConnEl.classList.add("hide")
            startupLoadEl.classList.remove("hide")
            el = null
        else
            startupConnEl.innerHTML = i18n.__(connection.infoText()
                # replace three dots
                .replace '…',''
                # add check connection to "Not Connected"
                .replace /(Not connected)/,
                         '$1 (check connection)')
            if document.querySelector('.connecting.hide')?
                el = notr {html:conninfo.el.innerHTML, stay:0, id:'conn'}
            else
                startupConnEl.classList.remove("hide")
                startupLoadEl.classList.add("hide")

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
        if Array.isArray viewstate.pos
            later -> remote.getCurrentWindow().setPosition viewstate.pos...
        applayout.left null
        applayout.convhead null
        applayout.main null
        applayout.maininfo null
        applayout.foot null
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
    convhead models
    controls models
    convlist models
    listhead models
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
