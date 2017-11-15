URL       = require 'url'
notifier  = require 'node-notifier'
AutoLaunch = require 'auto-launch'
clipboard = require('electron').clipboard

#
#
# Checks if the clipboard has pasteable content.
#
# Currently only text and images are supported
#
isContentPasteable = () ->
    formats = clipboard.availableFormats()
    # as more content is supported in clipboard it should be placed here
    pasteableContent = ['text/plain', 'image/png']
    isContentPasteable = 0
    for content in formats
        isContentPasteable += pasteableContent.includes(content)
    isContentPasteable > 0

notificationCenterSupportsSound = () ->
    # check if sound should be played via notification
    #  documentation says that only WindowsToaster and
    #  NotificationCenter supports sound
    playSoundIn = ['WindowsToaster', 'NotificationCenter']
    # check if currect notifier supports sound
    notifierSupportsSound = playSoundIn.find( (str) ->
        str == notifier.constructor.name
    )?

nameof = (e) -> e?.display_name ? e?.fallback_name ? e?.first_name ? 'Unknown'

initialsof = (e) ->
    if e?.first_name
        name = nameof e
        firstname = e?.first_name
        return  firstname.charAt(0) + name.replace(firstname, "").charAt(1)
    else if e?.display_name || e?.fallback_name
        name_to_split = e?.display_name ? e?.fallback_name
        name_splitted = name_to_split.split(' ')
        firstname = name_splitted[0].charAt(0)
        if name_splitted.length == 1
            return firstname.charAt(0)
        # just in case something strange
        else if name_splitted?.length == 0
            return '?'
        else
            lastname = name_splitted[name_splitted.length - 1]
            return firstname.charAt(0) + lastname.charAt(0)
    else
        return '?'

drawAvatar = (user_id, viewstate, entity, image = null, email = null, initials = null) ->
    #
    entity.needEntity(user_id) unless entity[user_id]?
    #
    # overwrites if entity is cached
    initials = initialsof(entity[user_id]).toUpperCase() if entity[user_id]?
    email    = entity[user_id]?.emails?[0] unless entity[user_id]?.emails?[0]?
    image    = entity[user_id]?.photo_url if entity[user_id]?.photo_url?
    #
    # Reproducible color code for initials
    #  see global.less for the color mapping [-1-25]
    #     -1: ? initials
    #   0-25: should be a uniform distribution of colors per users
    initialsCode = viewstate.cachedInitialsCode?[user_id] ? (if isNaN(user_id)
        initialsCode = -1
    else
        initialsCode = user_id % 26
    )
    #
    div class: 'avatar', 'data-id': user_id, ->
        if image?
            if !viewstate?.showAnimatedThumbs
                image += "?sz=50"
            #
            img src:fixlink(image)
            , "data-initials": initials
            , class: 'fallback-on'
            ,  onerror: (ev) ->
                # in case the image is not available, it
                #  fallbacks to initials
                ev.target.parentElement.classList.add "fallback-on"
            , onload: (ev) ->
                # when loading successfuly, update again all other imgs
                ev.target.parentElement.classList.remove "fallback-on"
        div class: "initials #{if image then 'fallback' else ''}"
        , 'data-first-letter': initialsCode
        , initials

nameofconv = (c) ->
    {entity} = require './models'
    part = c?.current_participant ? []
    ents = for p in part when not entity.isSelf p.chat_id
        entity[p.chat_id]
    name = ""
    one_to_one = c?.type?.indexOf('ONE_TO_ONE') >= 0
    if c?.name? and not one_to_one
        name = c.name
    else
        # all entities in conversation that is not self
        # the names of those entities
        names = ents.map nameof
        # joined together in a compelling manner
        name = names.join ', '
    return name


linkto = (c) -> "https://plus.google.com/u/0/#{c}/about"

later = (f) -> setTimeout f, 1

throttle = (ms, f) ->
    last = 0
    tim = null
    g = (as...) ->
        clearTimeout tim if tim
        if (d = (Date.now() - last)) > ms
            ret = f as...
            last = Date.now()
            ret
        else
            # ensure that last event is always fired
            tim = setTimeout (->g as...), d
            undefined

isAboutLink = (s) -> (/https:\/\/plus.google.com\/u\/0\/([0-9]+)\/about/.exec(s) ? [])[1]

getProxiedName = (e) ->
    s = e?.chat_message?.message_content?.segment?[0]
    return unless s
    return s?.formatting?.bold and isAboutLink(s?.link_data?.link_target)

tryparse = (s) -> try JSON.parse(s) catch err then undefined

fixlink = (l) -> if l?[0] == '/' then "https:#{l}" else l

topof = (el) -> el?.offsetTop + if el?.offsetParent then topof(el.offsetParent) else 0

uniqfn = (as, fn) ->
    fned = as.map fn
    as.filter (v, i) -> fned.indexOf(fned[i]) == i

isImg = (url) -> url?.match /\.(png|jpe?g|gif|svg)$/i

getImageUrl = (url="") ->
    return url if isImg url
    parsed = URL.parse url, true
    url = parsed.query.q
    return url if isImg url
    false

toggleVisibility = (element) ->
    if element.style.display == 'block'
        element.style.display = 'none'
    else
        element.style.display = 'block'

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

# AutoLaunch requires a path unless you are running in electron/nw
vesrions = process?.versions
if versions? and (versions.nw? or versions['node-webkit']? or versions.electron?)
    autoLaunchPath = undefined
else
    autoLaunchPath = process.execPath
autoLauncher = new AutoLaunch({
    name: 'YakYak',
    path: autoLaunchPath
});

module.exports = {nameof, initialsof, nameofconv, linkto, later,
                  throttle, uniqfn, isAboutLink, getProxiedName, tryparse,
                  fixlink, topof, isImg, getImageUrl, toggleVisibility,
                  convertEmoji, drawAvatar, notificationCenterSupportsSound,
                  insertTextAtCursor, isContentPasteable, autoLauncher}
