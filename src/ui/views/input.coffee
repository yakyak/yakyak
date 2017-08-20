autosize = require 'autosize'
clipboard = require('electron').clipboard
{scrollToBottom, messages} = require './messages'
{later, toggleVisibility, convertEmoji, insertTextAtCursor} = require '../util'

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
emojiSuggListIndex = -1
if document.querySelectorAll('.emoji-sugg-container').length
    document.querySelectorAll('.emoji-sugg-container')[0].parentNode.removeChild(document.querySelectorAll('.emoji-sugg-container')[0])

module.exports = view (models) ->
    div class:'input', ->
        div id: 'preview-container', ->
            div class: 'close-me material-icons'
                , onclick: (e) ->
                    clearsImagePreview()
                , ->
                    span ''
            div class: 'relative'
                , onclick: (e) ->
                    console.log 'going to upload preview image'
                    element = document.getElementById "message-input"
                    # send text
                    preparemessage element
                , ->
                    img id: 'preview-img', src: ''
                    div class: 'after material-icons'
                        , ->
                            span 'send'

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
            textarea id:'message-input', autofocus:true, placeholder: i18n.__('input.message:Message'), rows: 1, ''
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
                if (e.metaKey or e.ctrlKey) and e.key == 'ArrowUp' then action 'selectNextConv', -1
                if (e.metaKey or e.ctrlKey) and e.key == 'ArrowDown' then action 'selectNextConv', +1
                unless isModifierKey(e)
                    if e.keyCode == 27
                        e.preventDefault()
                        if models.viewstate.showtray && !models.viewstate.escapeClearsInput
                            action 'hideWindow'
                        else
                            # must focus on field and then execute:
                            #  - select all text in input
                            #  - replace them with an empty string
                            document.getElementById("message-input").focus()
                            document.execCommand("selectAll", false)
                            document.execCommand("insertText", false, "")
                            # also remove image preview
                            clearsImagePreview()

                    if e.keyCode == 13
                        e.preventDefault()
                        preparemessage e.target
                    if e.target.value == ''
                        if e.key is 'ArrowUp' then historyWalk e.target, -1
                        if e.key is 'ArrowDown' then historyWalk e.target, +1
                action 'lastkeydown', Date.now() unless isAltCtrlMeta(e)
            , onkeyup: (e) ->
                #check for emojis after pressing space
                element = document.getElementById "message-input";
                unicodeMap = require '../emojishortcode';
                emojiSuggListIndex = -1;
                if e.keyCode == 32
                    # Converts emojicodes (e.g. :smile:, :-) ) to unicode
                    if models.viewstate.convertEmoji
                        # get cursor position
                        startSel = element.selectionStart
                        len = element.value.length
                        element.value = convertEmoji(element.value)
                        # Set cursor position (otherwise it would go to end of inpu)
                        lenAfter = element.value.length
                        element.selectionStart = startSel - (len - lenAfter)
                        element.selectionEnd = element.selectionStart
                # remove emoji suggestion wrapper each time
                if document.querySelectorAll('.emoji-sugg-container').length
                    document.querySelectorAll('.emoji-sugg-container')[0].parentNode.removeChild(document.querySelectorAll('.emoji-sugg-container')[0])
                if element.value.length && models.viewstate.suggestEmoji
                    index = 0;
                    # read emoji table
                    for d, i of unicodeMap
                        # util function to know if a emoji is trying to be typed, to launch suggestion
                        emojiInserted = (emoji, text) ->
                            searchedText = text.substr(text.lastIndexOf(':'))
                            if searchedText == ':' || searchedText.indexOf(':') == -1
                                return false
                            return emoji.startsWith(searchedText) || emoji.indexOf(searchedText) > -1
                        # Insert suggestion
                        if  emojiInserted(d, element.value) && index < 5
                            emojiSuggList = document.querySelectorAll('.emoji-sugg-container')[0]
                            if !emojiSuggList
                                emojiSuggList = document.createElement('ul')
                                emojiSuggList.className = 'emoji-sugg-container'
                                element.parentNode.appendChild(emojiSuggList)
                            index++
                            emojiSuggItem = document.createElement('li')
                            emojiSuggItem.className = 'emoji-sugg'
                            emojiSuggItem.innerHTML = '<i>' + i + '</i>' + '<span>' + d + '</span>';
                            emojiSuggList.appendChild(emojiSuggItem)
                            emojiSuggItem.addEventListener('click', (->
                                emojiValue = this.querySelector('i').innerHTML;
                                finalText = document.getElementById('message-input').value.substr(0, document.getElementById('message-input').value.lastIndexOf(':')) + emojiValue
                                document.getElementById('message-input').value = finalText
                                if document.querySelectorAll('.emoji-sugg-container').length
                                    document.querySelectorAll('.emoji-sugg-container')[0].parentNode.removeChild(document.querySelectorAll('.emoji-sugg-container')[0])
                            ));
                            setTimeout(()->
                                emojiSuggList.classList.toggle('animate')
                            )
            , onpaste: (e) ->
                setTimeout () ->
                    if not clipboard.readImage().isEmpty() and not clipboard.readText()
                        action 'onpasteimage'
                , 2

            span class:'button-container', ->
                button title: i18n.__('input.emoticons:Show emoticons'), onclick: (ef) ->
                    document.querySelector('#emoji-container').classList.toggle('open')
                    scrollToBottom()
                , ->
                    span class:'material-icons', "mood"
            , ->
                button title: i18n.__('input.image:Attach image'), onclick: (ev) ->
                    document.getElementById('attachFile').click()
                , ->
                    span class:'material-icons', 'photo'
                input type:'file', id:'attachFile', accept:'.jpg,.jpeg,.png,.gif', onchange: (ev) ->
                    action 'uploadimage', ev.target.files

    # focus when switching convs
    if lastConv != models.viewstate.selectedConv
        lastConv = models.viewstate.selectedConv
        laterMaybeFocus()

#suggestEmoji : added enter handle and tab handle to navigate and select emoji when suggested
window.addEventListener('keydown', ((e) ->
    if models.viewstate.suggestEmoji
        if e.keyCode == 9 && document.querySelectorAll('.emoji-sugg-container')[0]
            emojiSuggListIndex++
            if emojiSuggListIndex == 5
                emojiSuggListIndex = 0
            for el in document.querySelectorAll('.emoji-sugg')
                el.classList.remove('activated')
            if document.querySelectorAll('.emoji-sugg')[emojiSuggListIndex]
                document.querySelectorAll('.emoji-sugg')[emojiSuggListIndex].classList.toggle('activated')
        if e.keyCode == 13 && document.querySelectorAll('.emoji-sugg-container')[0] && emojiSuggListIndex != -1
            newText = (originalText) ->
                newEmoji = document.querySelectorAll('.emoji-sugg')[emojiSuggListIndex].querySelector('i').innerText
                return originalText.substr(0, originalText.lastIndexOf(':')) + newEmoji;
            e.preventDefault();
            document.getElementById('message-input').value = newText(document.getElementById('message-input').value.trim())
).bind(this))

clearsImagePreview = ->
    element = document.getElementById 'preview-img'
    element.src = ''
    document.getElementById('attachFile').value = ''
    document.querySelector('#preview-container')
        .classList.remove('open')

laterMaybeFocus = -> later maybeFocus

maybeFocus = ->
    # no active element? or not focusing something relevant...
    el = document.activeElement
    if !el or not (el.nodeName in ['INPUT', 'TEXTAREA'])
        # steal it!!!
        el = document.querySelector('.input textarea')
        el.focus() if el

preparemessage = (ev) ->
    if models.viewstate.convertEmoji
        # before sending message, check for emoji
        element = document.getElementById "message-input"
        # Converts emojicodes (e.g. :smile:, :-) ) to unicode
        element.value = convertEmoji(element.value)
    #
    action 'sendmessage', ev.value, models.viewstate.googleVoiceMode
    #
    # check if there is an image in preview
    img = document.getElementById "preview-img"
    action 'uploadpreviewimage' if img.getAttribute('src') != ''
    #
    document.querySelector('#emoji-container').classList.remove('open')
    historyPush ev.value
    ev.value = ''
    autosize.update ev

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
