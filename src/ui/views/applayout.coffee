
{throttle} = require './vutil'

attached = false
attachListeners = ->
    return if attached
    window.addEventListener 'focus', onFocus
    window.addEventListener 'blur', onBlur
    window.addEventListener 'mousemove', onActivity
    window.addEventListener 'click', onActivity
    window.addEventListener 'keydown', onActivity

onFocus = (ev) ->
    maybeMoveFocus()
    action 'focus'

onBlur = (ev) ->
    action 'blur'

onActivity = throttle 100, (ev) ->
    action 'activity', ev.timeStamp ? Date.now()

onScroll = throttle 100, (ev) ->
    el = ev.target
    child = el.children[0]
    # calculation to see whether we are at the bottom with a tolerance value
    atbottom = (el.scrollTop + el.offsetHeight) >= (child.offsetHeight - 10)
    action 'atbottom', atbottom

maybeMoveFocus = ->
    return unless document.activeElement?.tagName == 'BODY'
    focusInput()


focusInput = ->
    document.querySelector('.input textarea')?.focus()


ondragover = ondragenter = (ev) ->
    # this enables dragging at all
    ev.preventDefault()
    return false


ondrop = (ev) ->
    ev.preventDefault()
    action 'drop', ev.dataTransfer.files


module.exports = layout ->
    div class:'applayout', {ondragover, ondragenter, ondrop}, ->
        div class:'left', region('left')
        div class:'right', ->
            div class:'main', region('main'), onscroll: onScroll
            div class:'foot', region('foot')
        div class:'info', region('info')
    attachListeners()
