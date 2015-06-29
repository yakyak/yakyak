autosize = require 'autosize'
clipboard = require 'clipboard'
messages = require './messages'

{later} = require '../util'

isModifierKey = (ev) -> ev.altKey || ev.ctrlKey || ev.metaKey || ev.shiftKey
isAltCtrlMeta = (ev) -> ev.altKey || ev.ctrlKey || ev.metaKey

cursorToEnd = (el) -> el.selectionStart = el.selectionEnd = el.value.length

history = []
historyIndex = 0
historyLength = 100
historyBackup = ""

historyPush = (data) ->
    history.push data
    if history.length == historyLength then history.shift()
    historyIndex = history.length

historyWalk = (el, offset) ->
    # if we are starting to dive into history be backup current message
    if offset is -1 and historyIndex is history.length then historyBackup = el.value
    historyIndex = historyIndex + offset
    # constrain index
    if historyIndex < 0 then historyIndex = 0
    if historyIndex > history.length then historyIndex = history.length
    # if don't have history value restore 'current message'
    val = history[historyIndex] or historyBackup
    el.value = val
    setTimeout (-> cursorToEnd el), 1

lastConv = null

module.exports = view (models) ->
    div class:'input', -> div ->
        textarea autofocus:true, placeholder:'Message', rows: 1, ''
        , onDOMNodeInserted: (e) ->
            # at this point the node is still not inserted
            ta = e.target
            later -> autosize ta
            ta.addEventListener 'autosize:resized', ->
                # we do this because the autosizing sets the height to nothing
                # while measuring and that causes the messages scroll above to
                # move. by pinning the div of the outer holding div, we
                # are not moving the scroller.
                ta.parentNode.style.height = (ta.offsetHeight + 24) + 'px'
                messages.scrollToBottom()
        , onkeydown: (e) ->
            if e.metaKey and e.keyIdentifier == 'Up' then action 'selectNextConv', -1
            if e.metaKey and e.keyIdentifier == 'Down' then action 'selectNextConv', +1
            unless isModifierKey(e)
                if e.keyCode == 13
                    e.preventDefault()
                    action 'sendmessage', e.target.value
                    historyPush e.target.value
                    e.target.value = ''
                    autosize.update e.target
                if e.target.value == ''
                    if e.keyIdentifier is "Up" then historyWalk e.target, -1
                    if e.keyIdentifier is "Down" then historyWalk e.target, +1
            action 'lastkeydown', Date.now() unless isAltCtrlMeta(e)
        , onpaste: (e) ->
            action 'onpasteimage' if not clipboard.readImage().isEmpty()
        button title:'Attach image', onclick: (ev) ->
            document.getElementById('attachFile').click()
        , ->
            span class:'icon-attach'
        input type:'file', id:'attachFile', accept:'.jpg,.jpeg,.png,.gif', onchange: (ev) ->
            action 'uploadimage', ev.target.files

    # focus when switching convs
    if lastConv != models.viewstate.selectedConv
        lastConv = models.viewstate.selectedConv
        laterMaybeFocus()

laterMaybeFocus = -> later maybeFocus

maybeFocus = ->
    # no active element? or not focusing something relevant...
    el = document.activeElement
    if !el or not (el.nodeName in ['INPUT', 'TEXTAREA'])
        # steal it!!!
        el = document.querySelector('.input textarea')
        el.focus() if el

handle 'noinputkeydown', (ev) ->
    el = document.querySelector('.input textarea')
    el.focus() if el and not isAltCtrlMeta(ev)
