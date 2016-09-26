autosize = require 'autosize'
clipboard = require('electron').clipboard
{scrollToBottom, messages} = require './messages'
{later, toggleVisibility, convertEmoji} = require '../util'

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

emojiCategories = require './emojicategories'
openByDefault = 'people'

module.exports = view (models) ->
    div class:'input', ->
        div id: 'preview-container', ->
            div class: 'relative'
                , onclick: (e) ->
                    console.log 'going to upload preview image'
                    action 'uploadpreviewimage'
                , ->
                    img id: 'preview-img', src: ''
                    div class: 'after material-icons'
                        , ->
                          span ''
                    div class: 'close-preview', ->
                        span ''

        div class: 'relative', ->
            div id:'emoji-container', ->
                div id:'emoji-group-selector', ->
                    for range in emojiCategories
                        name = range['title']
                        glow = ''
                        if name == openByDefault
                            glow = 'glow'
                        span id:name+'-button'
                        , title:name
                        , class:'emoticon ' + glow
                        , range['representation']
                        , onclick: do (name) -> ->
                            console.log("Opening " + name)
                            openEmoticonDrawer name

                div class:'emoji-selector', ->
                    for range in emojiCategories
                        name = range['title']
                        visible = ''
                        if name == openByDefault
                            visible = 'visible'

                        span id:name, class:'group-content ' + visible, ->
                            for emoji in range['range']
                                if emoji.indexOf("\u200d") >= 0
                                    # FIXME For now, ignore characters that have the "glue" character in them;
                                    # they don't render properly
                                    continue
                                span class:'emoticon', emoji
                                , onclick: do (emoji) -> ->
                                        element = document.getElementById "message-input"
                                        insertTextAtCursor element, emoji

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
                    messages.scrollToBottom() if messages?
            , onkeydown: (e) ->
                if (e.metaKey or e.ctrlKey) and e.keyIdentifier == 'Up' then action 'selectNextConv', -1
                if (e.metaKey or e.ctrlKey) and e.keyIdentifier == 'Down' then action 'selectNextConv', +1
                unless isModifierKey(e)
                    if e.keyCode == 27
                        e.preventDefault()
                        action 'hideWindow'
                    if e.keyCode == 13
                        e.preventDefault()
                        if models.viewstate.convertEmoji
                            # before sending message, check for emoji
                            element = document.getElementById "message-input"
                            # Converts emojicodes (e.g. :smile:, :-) ) to unicode
                            element.value = convertEmoji(element.value)
                        #
                        action 'sendmessage', e.target.value
                        document.querySelector('#emoji-container').classList.remove('open');
                        historyPush e.target.value
                        e.target.value = ''
                        autosize.update e.target
                    if e.target.value == ''
                        if e.keyIdentifier is "Up" then historyWalk e.target, -1
                        if e.keyIdentifier is "Down" then historyWalk e.target, +1
                action 'lastkeydown', Date.now() unless isAltCtrlMeta(e)
            , onkeyup: (e) ->
                #check for emojis after pressing space
                if e.keyCode == 32
                    element = document.getElementById "message-input"
                    # get cursor position
                    startSel = element.selectionStart
                    endSel  = element.selectionEnd
                    # Converts emojicodes (e.g. :smile:, :-) ) to unicode
                    if models.viewstate.convertEmoji
                        element.value = convertEmoji(element.value)
                    # Set cursor position (otherwise it would go to end of inpu)
                    element.selectionStart = startSel
                    element.selectionEnd = endSel
            , onpaste: (e) ->
                setTimeout () ->
                    if not clipboard.readImage().isEmpty() and not clipboard.readText()
                        action 'onpasteimage'
                , 2

            span class:'button-container', ->
                button title:'Show emoticons', onclick: (ef) ->
                    document.querySelector('#emoji-container').classList.toggle('open');
                    scrollToBottom()
                , ->
                    span class:'material-icons', "mood"
            , ->
                button title:'Attach image', onclick: (ev) ->
                    document.getElementById('attachFile').click()
                , ->
                    span class:'material-icons', 'photo'
                input type:'file', id:'attachFile', accept:'.jpg,.jpeg,.png,.gif', onchange: (ev) ->
                    action 'uploadimage', ev.target.files
    , onDOMNodeInserted: (e) ->
            window.twemoji?.parse e.target

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

openEmoticonDrawer = (drawerName) ->
    for range in emojiCategories
        set = (range['title'] == drawerName)
        setClass set, (document.querySelector '#'+range['title']), 'visible'
        setClass set, (document.querySelector '#'+range['title']+'-button'), 'glow'


setClass = (boolean, element, className) ->
    if element == undefined or element == null
        console.error "Cannot set visibility for undefined variable"
    else
        if boolean
            element.classList.add(className)
        else
            element.classList.remove(className)


insertTextAtCursor = (el, text) ->
    value = el.value
    doc = el.ownerDocument
    if typeof el.selectionStart == "number" and typeof el.selectionEnd == "number"
        endIndex = el.selectionEnd
        el.value = value.slice(0, endIndex) + text + value.slice(endIndex)
        el.selectionStart = el.selectionEnd = endIndex + text.length
        el.focus()
    else if doc.selection != "undefined" and doc.selection.createRange
        el.focus()
        range = doc.selection.createRange()
        range.collapse(false)
        range.text = text
        range.select()
