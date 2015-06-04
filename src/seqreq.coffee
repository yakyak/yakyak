
totallyunique = (as...) -> String(Date.now()) + (Math.random() * 1000000)

# fn is expected to return a promised that finishes
# when fn is finished.
#
# retry is whether we retry failures of fn
#
# dedupe is a function that mashes the arguments to fn
# into a dedupe value.
module.exports = (fn, retry, dedupe = totallyunique) ->

    queue = []      # the queue of args to exec
    deduped = []    # the dedupe(args) for deduping
    execing = false # flag indicating whether execNext is running

    # will perpetually exec next until queue is empty
    execNext = ->
        unless queue.length
            execing = false
            return
        execing = true
        args = queue[0] # next args to try
        fn(args...).then ->
            # it finished, drop args
            queue.shift(); deduped.shift()
        .fail (err) ->
            # it failed.
            # no retry? then just drop args
            (queue.shift(); deduped.shift()) unless retry
        .then ->
            execNext()

    (as...) ->
        d = dedupe as...
        if (i = deduped.indexOf(d)) >= 0
            # replace entry, notice this can replace
            # a currently execing entry
            queue[i] = as
        else
            # push a new entry
            queue.push as
            deduped.push d
        execNext() unless execing
