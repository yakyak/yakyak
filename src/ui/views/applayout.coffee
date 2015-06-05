
{throttle} = require './vutil'

attached = false
attachListeners = ->
    return if attached
    window.addEventListener 'mousemove', onActivity
    window.addEventListener 'click', onActivity
    window.addEventListener 'keydown', onActivity

onActivity = throttle 100, (ev) ->
    action 'activity', ev.timeStamp ? Date.now()

onScroll = throttle 100, (ev) ->
    el = ev.target
    child = el.children[0]
    # calculation to see whether we are at the bottom with a tolerance value
    atbottom = (el.scrollTop + el.offsetHeight) >= (child.offsetHeight - 10)
    action 'atbottom', atbottom




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
    leftResize: (ev) -> action 'leftresize', ev.clientX


module.exports = layout ->
    div class:'applayout', drag, resize, ->
        div class:'left', ->
            div class:'list', region('left')
            div class:'lfoot', region('lfoot')
        div class:'leftresize', 'data-resize':'leftResize'
        div class:'right', ->
            div class:'main', region('main'), onscroll: onScroll
            div class:'foot', region('foot')
        div class:'info', region('info')
    attachListeners()
