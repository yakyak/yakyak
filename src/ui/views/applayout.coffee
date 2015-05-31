
attached = false
attachListeners = ->
    return if attached
    window.addEventListener 'focus', onFocus


onFocus = (ev) ->
    maybeMoveFocus()


maybeMoveFocus = ->
    return unless document.activeElement?.tagName == 'BODY'
    focusInput()


focusInput = ->
    document.querySelector('.input textarea')?.focus()


module.exports = layout ->
    div class:'applayout', ->
        div class:'left', region('left')
        div class:'right', ->
            div class:'main', region('main')
            div class:'foot', region('foot')
    attachListeners()
