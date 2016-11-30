URL = require 'url'
notifier = require 'node-notifier'

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
    else
        return '?'

drawAvatar = (user_id, viewstate, entity) ->
    initials = initialsof entity[user_id]
    div class: 'avatar', 'data-id': user_id, ->
        image = entity[user_id]?.photo_url
        if image
            if !viewstate?.showAnimatedThumbs
                image += "?sz=50"
            #
            img src:fixlink(image), "data-initials": initials
            ,  onerror: (ev) ->
                # in case the image is not available, it
                #  fallbacks to initials
                ev.target.parentElement.classList.add "fallback-on"
            , onload: (ev) ->
                # when loading successfuly, update again all other imgs
                ev.target.parentElement.classList.remove "fallback-on"
            div class:'initials fallback', initials
        else
            div class:'initials', initials

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

convertEmoji = (text) ->
    unicodeMap = require './emojishortcode'

    patterns = [
        "(^|[ ])(:[a-zA-Z0-9_\+-]+:)([ ]|$)",
        "(^|[ ])(:\\(:\\)|:\\(\\|\\)|:X\\)|:3|\\(=\\^\\.\\.\\^=\\)|\\(=\\^\\.\\^=\\)|=\\^_\\^=|x_x|X-O|X-o|X\\(|X-\\(|O\\.O|:O|:-O|=O|o\\.o|:o|:-o|=o|D:|>_<|T_T|:'\\(|;_;|='\\(|>\\.<|>:\\(|>:-\\(|>=\\(|:\\(|:-\\(|=\\(|;P|;-P|;p|;-p|:P|:-P|=P|:p|:-p|=p|;\\*|;-\\*|:\\*|:-\\*|:S|:-S|:s|:-s|=\\/|=\\\\|:-\\/|:-\\\\|:\\/|:\\\\|u_u|o_o;|-_-|=\\||:\\||:-\\||B-\\)|B\\)|;-\\)|;\\)|}=\\)|}:-\\)|}:\\)|O=\\)|O:-\\)|O:\\)|\\^_\\^;;|=D|\\^_\\^|:-D|:D|~@~|<3|<\\/3|<\\\\3|\\(]:{|-<@%|:\\)|:-\\)|=\\))([ ]|$)"
    ]

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

module.exports = {nameof, initialsof, nameofconv, linkto, later,
                  throttle, uniqfn, isAboutLink, getProxiedName, tryparse,
                  fixlink, topof, isImg, getImageUrl, toggleVisibility,
                  convertEmoji, drawAvatar, notificationCenterSupportsSound}
