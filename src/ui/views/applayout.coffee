
{throttle, topof} = require '../util'

path = require 'path'

attached = false
attachListeners = ->
    return if attached
    window.addEventListener 'mousemove', onActivity
    window.addEventListener 'click', onActivity
    window.addEventListener 'keydown', onActivity
    window.addEventListener 'keydown', noInputKeydown

onActivity = throttle 100, (ev) ->
    # This occasionally happens to generate error when
    # user clicking has generated an application event
    # that is being handled while we also receive the event
    # Current fix: defer the action generated during the update
    setTimeout ->
      action 'activity', ev.timeStamp ? Date.now()
    , 1

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

addClass = (el, cl) ->
    return unless el
    return if RegExp("\\s*#{cl}").exec el.className
    el.className += if el.className then " #{cl}" else cl
    el

removeClass = (el, cl) ->
    return unless el
    el.className = el.className.replace RegExp("\\s*#{cl}"), ''
    el

closest = (el, cl) ->
    return unless el
    cl = RegExp("\\s*#{cl}") unless cl instanceof RegExp
    if el.className.match(cl) then el else closest(el.parentNode, cl)

drag = do ->

    ondragover = ondragenter = (ev) ->
        # this enables dragging at all
        ev.preventDefault()
        addClass closest(ev.target, 'dragtarget'), 'dragover'
        removeClass closest(ev.target, 'dragtarget'), 'drag-timeout'
        ev.dataTransfer.dropEffect = 'copy'
        return false

    ondrop = (ev) ->
        ev.preventDefault()
        removeClass closest(ev.target, 'dragtarget'), 'dragover'
        removeClass closest(ev.target, 'dragtarget'), 'drag-timeout'
        action 'uploadimage', ev.dataTransfer.files

    ondragleave = (ev) ->
        # it was firing the leave event while dragging, had to
        #  use a timeout to check if it was a "real" event
        #  by remaining out
        addClass closest(ev.target, 'dragtarget'), 'drag-timeout'
        setTimeout ->
            if closest(ev.target, 'dragtarget').classList.contains('drag-timeout')
                removeClass closest(ev.target, 'dragtarget'), 'dragover'
                removeClass closest(ev.target, 'dragtarget'), 'drag-timeout'
        , 200

    {ondragover, ondragenter, ondrop, ondragleave}


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
    platform = if process.platform is 'darwin' then 'osx' else ''
    div class:'applayout ' + platform, resize, region('last'), ->
        div class:'left', ->
            div class:'listhead', region('listhead')
            div class:'list', region('left')
            div class:'lfoot', region('lfoot')
        div class:'leftresize', 'data-resize':'leftResize'
        div class:'right dragtarget ', drag, ->
            div id: 'drop-overlay', ->
                div class: 'inner-overlay', () ->
                    div 'Drop file here.'
            div class:'convhead', region('convhead')
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
