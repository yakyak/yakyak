
{throttle, topof} = require '../util'

attached = false
attachListeners = ->
    return if attached
    window.addEventListener 'mousemove', onActivity
    window.addEventListener 'click', onActivity
    window.addEventListener 'keydown', onActivity
    window.addEventListener 'keydown', noInputKeydown

onActivity = throttle 100, (ev) ->
    action 'activity', ev.timeStamp ? Date.now()

noInputKeydown = (ev) ->
    action 'noinputkeydown', ev if ev.target.tagName != 'TEXTAREA'

onScroll = throttle 20, (ev) ->
    el = ev.target
    child = el.children[0]

    # calculation to see whether we are at the bottom with a tolerance value
    atbottom = (el.scrollTop + el.offsetHeight) >= (child.offsetHeight - 10)
    action 'atbottom', atbottom

    # check whether we are at the top with a tolerance value
    attop = el.scrollTop <= (el.offsetHeight / 2)
    action 'attop', attop

drag = do ->

    ondragover = ondragenter = (ev) ->
        # this enables dragging at all
        ev.preventDefault()
        return false

    ondrop = (ev) ->
        ev.preventDefault()
        action 'drop', ev.dataTransfer.files

    {ondragover, ondragenter, ondrop}


resize = do ->
    rz = null
    {
        onmousemove: (ev) ->
            if rz and ev.buttons & 1
                rz(ev)
            else
                rz = null
        onmousedown: (ev) ->
            rz = resizers[ev.target.dataset?.resize]
        onmouseup: (ev) ->
            rz = null
    }

resizers =
    leftResize: (ev) -> action 'leftresize', (Math.max 90, ev.clientX)


module.exports = exp = layout ->
    div class:'applayout', drag, resize, ->
        div class:'left', ->
            div class:'list', region('left')
            div class:'lfoot', region('lfoot')
        div class:'leftresize', 'data-resize':'leftResize'
        div class:'right', ->
            div class:'main', region('main'), onscroll: onScroll
            div class:'maininfo', region('maininfo')
            div class:'foot', region('foot')
    attachListeners()


do ->
    id = ofs = null

    lastVisibleMessage = ->
        # the viewport
        screl = document.querySelector('.main')
        # the pixel offset for the bottom of the viewport
        bottom = screl.scrollTop + screl.offsetHeight
        # all messages
        last = null
        last = m for m in document.querySelectorAll('.message') when topof(m) < bottom
        return last

    exp.recordMainPos = ->
        el = lastVisibleMessage()
        id = el?.id
        return unless el and id
        ofs = topof el

    exp.adjustMainPos = ->
        return unless id and ofs
        el = document.getElementById id
        nofs = topof el
        # the size of the inserted elements
        inserted = nofs - ofs
        screl = document.querySelector('.main')
        screl.scrollTop = screl.scrollTop + inserted
        # reset
        id = ofs = null
