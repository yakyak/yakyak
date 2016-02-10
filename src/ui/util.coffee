URL = require 'url'

nameof = (e) -> e?.display_name ? e?.fallback_name ? e?.first_name ? 'Unknown'

nameofconv = (c) ->
    {entity} = require './models'
    part = c?.current_participant ? []
    ents = for p in part when not entity.isSelf p.chat_id
        entity[p.chat_id]
    entity[p.chat_id]
    name = ""
    one_to_one = c?.type?.indexOf('ONE_TO_ONE') >= 0
    if c.name? and not one_to_one
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

module.exports = {nameof, nameofconv, linkto, later, throttle, uniqfn,
isAboutLink, getProxiedName, tryparse, fixlink, topof, isImg, getImageUrl,
toggleVisibility}
