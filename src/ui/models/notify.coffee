
tonotify = []

module.exports =
    addToNotify: (ev) -> tonotify.push ev
    popToNotify: ->
        return [] unless tonotify.length
        t = tonotify
        tonotify = []
        return t
