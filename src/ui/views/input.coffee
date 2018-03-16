autosize = require 'autosize'
clipboard = require('electron').clipboard
nativeImage =require('electron').nativeImage
{scrollToBottom, messages} = require './messages'
{later, toggleVisibility, emojiReplaced, emojiToHtml} = require '../util'

isModifierKey = (ev) -> ev.altKey || ev.ctrlKey || ev.metaKey || ev.shiftKey
isAltCtrlMeta = (ev) -> ev.altKey || ev.ctrlKey || ev.metaKey

cursorToEnd = (el) -> el.selectionStart = el.selectionEnd = el.value.length
unicodeMap = require '../emojishortcode';
history = []
historyIndex = 0
historyLength = 100
historyBackup = ""
inputDivSelection = null


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

getDataUri = (url, callback) ->
  image = new Image

  image.onload = ->
    canvas = document.createElement('canvas')
    canvas.width = @naturalWidth
    canvas.height = @naturalHeight
    canvas.getContext('2d').drawImage this, 0, 0
    callback canvas.toDataURL('image/png')
    return

  image.src = url
  return

sendSticker = (dataUrl) ->
  stickerImage = nativeImage.createFromDataURL(dataUrl)
  clipboard.writeImage stickerImage
  document.querySelector('#stickers-container').classList.remove('open')
  action 'onpasteimage'

getColorEmoji = (character, viewstate, returnObject) ->
    
    d = document.createElement('div')
    if viewstate.emojiType == "twitter"
        d.innerHTML=twemoji.parse(character)
    else
        emojione.greedyMatch = true
        d.innerHTML= emojione.toImage(character)

    if typeof d.firstChild.getAttribute == "function"
        returnObject.src =d.firstChild.getAttribute("src")
        returnObject.alt =d.firstChild.getAttribute("alt")   

emojiCharToHTML = (character, viewstate) ->   
    if viewstate.emojiType == "default"
        return character
    else
        if viewstate.emojiType == "twitter"
            return twemoji.parse(character).replace("emoji","colorEmoji")
        else
            return emojione.toImage(character).replace("class=\"emojione\"","class=\"colorEmoji\"")

placeCaretAtEnd = (el, moveTo) ->
    el.focus()
    if typeof window.getSelection != "undefined" and typeof document.createRange != "undefined"
        range = document.createRange()
        range.setStartBefore(moveTo) 
        range.collapse(false)
        sel = window.getSelection()
        sel.removeAllRanges()
        sel.addRange(range)

escapeRegExp = (text) ->
  text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')


convertEmoji = (text) ->
    unicodeMap = require './emojishortcode'
    inferedPattern = "(^|[ ])" +
    "(:\\(:\\)|:\\(\\|\\)|:X\\)|:3|\\(=\\^\\.\\.\\^=\\)|\\(=\\^\\.\\^=\\)|=\\^_\\^=|" +
    (escapeRegExp(el) for el in Object.keys(unicodeMap)).join('|') +
    ")([ ]|$)"

    patterns = [inferedPattern]

    emojiCodeRegex = new RegExp(patterns.join('|'),'g')

    text = text.replace(emojiCodeRegex, (emoji) ->
        suffix = emoji.slice(emoji.trimRight().length)
        prefix = emoji.slice(0, emoji.length - emoji.trimLeft().length)
        unicode = unicodeMap[emoji.trim()]
        if unicode?
            prefix + unicode + suffix
        else
            emoji
    )
    return text


convertEmojiCode = (elArg, viewstate) ->
    #unicodeMap = require './emojishortcode'
    inferedPattern = "(^|[ ])" +
    "(:\\(:\\)|:\\(\\|\\)|:X\\)|:3|\\(=\\^\\.\\.\\^=\\)|\\(=\\^\\.\\^=\\)|=\\^_\\^=|" +
    (escapeRegExp(el) for el in Object.keys(unicodeMap)).join('|') +
    ")([ ]|$)"
    patterns = [inferedPattern]
    for node in elArg.childNodes
        
        emojiCodeRegex = new RegExp(patterns.join('|'),'g')
        emoji=node.textContent
        matches = emoji.trim().match(emojiCodeRegex)
        code =''
        if matches
            e =  matches[0]
            suffix = e.slice(e.trimRight().length)
            prefix = e.slice(0, e.length - e.trimLeft().length)
            unicode = unicodeMap[e.trim()]
            if unicode?
                code= prefix + unicode + suffix

                start = node.textContent.indexOf(e)
                end = node.textContent.indexOf(e)+e.length

                stringToConvert = node.textContent.slice(start, end)

                temp_container = document.createElement('div')
                temp_container.innerHTML=emojiCharToHTML(code, viewstate)
                emo = (temp_container).querySelectorAll(".colorEmoji")[0] || temp_container.firstChild

                beforeText = document.createTextNode(node.textContent.slice(0, start).replace(/\u00a0/g, " "))
                afterText = document.createTextNode(node.textContent.slice(end).replace(/\u00a0/g, " "))

                node.parentNode.insertBefore(beforeText, node)
                node.parentNode.insertBefore(afterText, node.nextSibling)
                node.parentNode.replaceChild(emo, node)
                placeCaretAtEnd(elArg, emo.nextSibling)
                convertEmojiCode(elArg) 


saveSelection =() ->
    if window.getSelection
        sel = window.getSelection()
        if sel.getRangeAt and sel.rangeCount
            return sel.getRangeAt(0)
    else 
        if document.selection and document.selection.createRange
            return document.selection.createRange()
    return null

restoreSelection=(range) ->
    if range
        if window.getSelection 
            sel = window.getSelection()
            sel.removeAllRanges()
            sel.addRange(range)
        else 
            if document.selection && range.select
                range.select()

insertEmojiAtCursor = (el, src, alt, className) ->
    restoreSelection(inputDivSelection)
    value = el.innerHTML
    emoji = img src:src, alt:alt, class:className
    doc = el.ownerDocument
    el.focus()
    range = doc.getSelection().getRangeAt(0)
    range.deleteContents()
    range.collapse(false)
    doc.execCommand('insertHTML', false, emoji)
    img src:src, alt:alt, class:className

insertTextAtCursor = (el,text) ->
    restoreSelection(inputDivSelection)
    doc = el.ownerDocument
    el.focus()
    range = doc.getSelection().getRangeAt(0)
    range.deleteContents()
    range.collapse(false)
    doc.execCommand('insertHTML', false, text)



emojiCategories = require './emojicategories'
stickerCategories = require './stickercategories'

openByDefault = 'people'
openByDefaultSticker = 'Internet'
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
                        if models.viewstate.emojiType == "default"
                            span id:name+'-button'
                            , title:name
                            , class:'emoticon ' + glow
                            , range['representation']
                            , onclick: do (name) -> ->
                                console.log("Opening " + name)
                                openEmoticonDrawer name
                        else
                            imageParam ={src: '', alt:''}
                            getColorEmoji(range['representation'],models.viewstate, imageParam)
                            img id:name+'-button',title:name, src:imageParam.src, alt:imageParam.alt, class:'emoticon ' + glow
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
                                if models.viewstate.emojiType == "default"
                                    if emoji.indexOf("\u200d") >= 0
                                        # FIXME For now, ignore characters that have the "glue" character in them;
                                        # they don't render properly
                                       continue
                                    span class:'emoticon', emoji
                                    , onclick: do (emoji) -> ->
                                        element = document.getElementById "message-input"
                                        insertTextAtCursor element, emoji
                                else
                                    emojiHtml=emojiCharToHTML(emoji, models.viewstate)
                                    emojiReplace=emojiReplaced(emoji, models.viewstate)
                                    if emojiReplace
                                        d = document.createElement('div')
                                        d.innerHTML=emojiHtml
                                        if typeof d.firstChild.getAttribute == "function"
                                            src =d.firstChild.getAttribute("src")
                                            alt =d.firstChild.getAttribute("alt") 
                                    
                                        img src:src, alt:alt, class:'colorEmoji'
                                        , onclick: do (src, alt) -> ->
                                            element = document.getElementById "message-input"
                                            insertEmojiAtCursor element, src, alt, 'colorEmoji'

        div class: 'relative', ->
            div id:'stickers-container', ->
                div id:'stickers-group-selector', ->
                    for range in stickerCategories
                        name = range['title']
                        path = range['representation']
                        glow = ''
                        if name == openByDefaultSticker
                            glow = 'glow'
                        img src:path
                        , id:name+'-button'
                        , title:name
                        , class: 'stickericon '+glow
                        , onclick: do (name) -> ->
                            console.log("Opening " + name)
                            openStickerDrawer name

                div class:'sticker-selector', ->
                    for range in stickerCategories
                        name = range['title']
                        visible = ''
                        if name == openByDefaultSticker
                            visible = 'visible'

                        span id:name, class:'group-content ' + visible, ->
                            for sticker in range['range']
                                img src: sticker
                                , class: 'sticker '
                                , onclick: do (sticker) -> ->
                                    getDataUri(sticker, sendSticker);


        div class:'input-container', ->
            #textarea id:'message-input', autofocus:true, placeholder: i18n.__('input.message:Message'), rows: 1, ''
            div contenteditable:true, id:'message-input', autofocus:true, placeholder: i18n.__('input.message:Message'), rows: 1, ''
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
                        for und in e.target.querySelectorAll("undefined")
                                e.target.removeChild(und)
                        if e.target.lastChild.nodeType == 3
                            if e.target.lastChild.nodeValue.slice(-1)=="\u00a0"
                                e.target.lastChild.nodeValue = e.target.lastChild.nodeValue.replace(/.$/," ")
                        e.preventDefault()
                        preparemessage e.target
                    if e.target.value == ''
                        if e.key is 'ArrowUp' then historyWalk e.target, -1
                        if e.key is 'ArrowDown' then historyWalk e.target, +1
                action 'lastkeydown', Date.now() unless isAltCtrlMeta(e)
            , onkeyup: (e) ->
                #check for emojis after pressing space
                element = document.getElementById "message-input";
                #unicodeMap = require '../emojishortcode';
                emojiSuggListIndex = -1;
                if e.keyCode == 32
                    # Converts emojicodes (e.g. :smile:, :-) ) to unicode
                    for und in element.querySelectorAll("undefined")
                            element.removeChild(und)
                    
                    if models.viewstate.convertEmoji
                        convertEmojiCode(element, models.viewstate)
                # remove emoji suggestion wrapper each time
                if document.querySelectorAll('.emoji-sugg-container').length
                    document.querySelectorAll('.emoji-sugg-container')[0].parentNode.removeChild(document.querySelectorAll('.emoji-sugg-container')[0])
                if element.innerHTML.length && models.viewstate.suggestEmoji
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
                        if  emojiInserted(d, element.innerHTML) && index < 5
                            emojiSuggList = document.querySelectorAll('.emoji-sugg-container')[0]
                            if !emojiSuggList
                                emojiSuggList = document.createElement('ul')
                                emojiSuggList.className = 'emoji-sugg-container'
                                element.parentNode.appendChild(emojiSuggList)
                            index++
                            emojiSuggItem = document.createElement('li')
                            emojiSuggItem.className = 'emoji-sugg'
                            emojiSuggItem.innerHTML = '<i>' + emojiCharToHTML(i, models.viewstate) + '</i>' + '<span>' + d + '</span>';
                            emojiSuggList.appendChild(emojiSuggItem)
                            emojiSuggItem.addEventListener('click', (->
                                emojiValue = this.querySelector('i').innerHTML;
                                finalText = document.getElementById('message-input').innerHTML.substr(0, document.getElementById('message-input').innerHTML.lastIndexOf(':')) + emojiValue
                                document.getElementById('message-input').innerHTML = finalText
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
            ,onblur: (e)->
                inputDivSelection=saveSelection()
            span class:'button-container', ->
                button title: i18n.__('input.emoticons:Show emoticons'), onclick: (ef) ->
                    document.querySelector('#emoji-container').classList.toggle('open')
                    scrollToBottom()
                , ->
                    if (models.viewstate.emojiType!="default")
                        imageParam ={src: '', alt:''}
                        getColorEmoji(twemoji.convert.fromCodePoint('+1f60b'), models.viewstate,imageParam)
                        img src:imageParam.src, alt:imageParam.alt, class:'material-icons'
                    else
                        span class:'material-icons', "mood"

            , ->
                button title: i18n.__('input.image:Attach image'), onclick: (ev) ->
                    document.getElementById('attachFile').click()
                , ->
                    if (models.viewstate.emojiType!="default")
                        imageParam ={src: '', alt:''}
                        getColorEmoji(twemoji.convert.fromCodePoint('+1f5bc'),models.viewstate, imageParam)
                        img src:imageParam.src, alt:imageParam.alt, class:'material-icons'
                        input type:'file', id:'attachFile', accept:'.jpg,.jpeg,.png,.gif', onchange: (ev) ->
                            action 'uploadimage', ev.target.files
                    else
                        span class:'material-icons', 'photo'    
            , ->
                button title: i18n.__('input.emoticons:Show stickers'), onclick: (ef) ->
                    document.querySelector('#stickers-container').classList.toggle('open')
                    scrollToBottom()
                , ->
                    if (models.viewstate.emojiType!="default")
                        imageParam ={src: '', alt:''}
                        getColorEmoji(twemoji.convert.fromCodePoint('+1f439'), models.viewstate,imageParam)
                        img src:imageParam.src, alt:imageParam.alt, class:'material-icons'
                    else
                        span class:'material-icons', 'photo'    
                    


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

emojiChangeBack = (ev) ->
    emojies = ev.querySelectorAll(".colorEmoji")
    for emoji in emojies
        textnode = document.createTextNode(emoji.alt);
        emoji.parentNode.replaceChild(textnode, emoji)
    return ev.innerHTML
            

preparemessage = (ev) ->
    if models.viewstate.emojiType!="default"
        text=emojiChangeBack(ev)
    else 
        text = ev.innerHTML
    text.replace(/%20/g, " ");
    
    if models.viewstate.convertEmoji
        # before sending message, check for emoji
        #element = document.getElementById "message-input"
        # Converts emojicodes (e.g. :smile:, :-) ) to unicode
        text = convertEmoji(text)
    #
    action 'sendmessage', text
    #
    # check if there is an image in preview
    img = document.getElementById "preview-img"
    action 'uploadpreviewimage' if img.getAttribute('src') != ''
    #
    document.querySelector('#emoji-container').classList.remove('open')
    document.querySelector('#stickers-container').classList.remove('open')
    historyPush text
    ev.innerHTML = ''
    autosize.update ev

handle 'noinputkeydown', (ev) ->
    el = document.querySelector('.input textarea')
    el.focus() if el and not isAltCtrlMeta(ev)

openEmoticonDrawer = (drawerName) ->
    for range in emojiCategories
        set = (range['title'] == drawerName)
        setClass set, (document.querySelector '#'+range['title']), 'visible'
        setClass set, (document.querySelector '#'+range['title']+'-button'), 'glow'


openStickerDrawer = (drawerName) ->
    for range in stickerCategories
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
