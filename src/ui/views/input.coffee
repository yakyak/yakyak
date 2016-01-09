autosize = require 'autosize'
clipboard = require 'clipboard'
messages = require './messages'

{later, toggleVisibility} = require '../util'

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


emoticonCodeRanges =
    emoticons:                          [0x1F600..0x1F64F]
    miscellaneousSymbols:               [0x2600..0x26FF]
    miscellaneousSymbolsAndPictographs: [0x1F300..0x1F5FF]
    supplementalSymbolsAndPictographs:  [0x1F900..0x1F9FF]
    transportAndMapSymbols:             [0x1F680..0x1F6FF]



module.exports = view (models) ->
    div class:'input', ->
        div id:'emoji-selector', ->
            for i in emoticonCodeRanges['emoticons']
                span transposedFromCharCode(i)
                , onclick: (e) ->
                    value = e.target.innerHTML
                    element = document.getElementById "message-input"
                    insertTextAtCursor element, value

        div class:'input-container', ->
            textarea id:'message-input', autofocus:true, placeholder:'Message', rows: 1, ''
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
                if (e.metaKey or e.ctrlKey) and e.keyIdentifier == 'Up' then action 'selectNextConv', -1
                if (e.metaKey or e.ctrlKey) and e.keyIdentifier == 'Down' then action 'selectNextConv', +1
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
                setTimeout () ->
                    if not clipboard.readImage().isEmpty() and not clipboard.readText()
                        action 'onpasteimage'
                , 2

            span class:'button-container', ->
                button title:'Show emoticons', onclick: (ef) ->
                    elem = document.getElementById 'emoji-selector'
                    console.log elem
                    toggleVisibility elem
                , ->
                    span class:'icon-emoji'
            , ->
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

transposedFromCharCode = (codePt) ->
    if codePt > 0xFFFF
        codePt -= 0x10000;
        String.fromCharCode(0xD800 + (codePt >> 10), 0xDC00 + (codePt & 0x3FF))
    else
        String.fromCharCode(codePt)


insertTextAtCursor = (el, text) ->
    value = el.value
    endIndex
    range
    doc = el.ownerDocument
    if typeof el.selectionStart == "number" and typeof el.selectionEnd == "number"
        endIndex = el.selectionEnd
        el.value = value.slice(0, endIndex) + text + value.slice(endIndex)
        el.selectionStart = el.selectionEnd = endIndex + text.length
    else if doc.selection != "undefined" and doc.selection.createRange
        el.focus()
        range = doc.selection.createRange()
        range.collapse(false)
        range.text = text
        range.select()
