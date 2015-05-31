
nameof = (e) -> e?.display_name ? e?.fallback_name ? e?.first_name ? 'Unknown'

linkto = (c) -> "https://plus.google.com/u/0/#{c}/about"

forceredraw = (sel) ->
    setTimeout ->
        return unless el = document.querySelector sel
        el.style.display = 'none'
        el.offsetHeight # no need to store this anywhere, the reference is enough
        el.style.display = ''
    , 1

later = (f) -> setTimeout f, 1

module.exports = {nameof, linkto, forceredraw, later}
