
nameof = (e) -> e?.display_name ? e?.fallback_name ? e?.first_name ? 'Unknown'

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
    return s?.formatting?.bold == 1 and isAboutLink(s?.link_data?.link_target)

module.exports = {nameof, linkto, later, throttle, isAboutLink, getProxiedName}
