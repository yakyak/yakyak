
nameof = (e) -> e?.display_name ? e?.fallback_name ? e?.first_name ? 'Unknown'
linkto = (c) -> "https://plus.google.com/u/0/#{c}/about"

module.exports = {nameof, linkto}
