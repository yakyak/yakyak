
nameof = (e) -> e?.display_name ? e?.fallback_name ? e?.first_name ? 'Unknown'

linkto = (c) -> "https://plus.google.com/u/0/#{c}/about"

later = (f) -> setTimeout f, 1

unread = (conv) ->
    t = conv?.self_conversation_state?.self_read_state?.latest_read_timestamp
    c = 0
    for e in conv?.event ? []
        c++ if e.chat_message and e.timestamp > t
    c

module.exports = {nameof, linkto, later, unread}
