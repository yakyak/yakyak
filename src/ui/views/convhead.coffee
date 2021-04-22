{nameofconv}  = require '../util'

ipc       = require('electron').ipcRenderer
moment    = require('moment')

onclickaction = (a) -> (ev) -> action a

updateActiveTimer = null

module.exports = view (models) ->
  {conv, viewstate} = models

  if !viewstate.useSystemDateFormat
    moment.locale(i18n.getLocale())
  else
    moment.locale(window.navigator.language)

  conv_id = viewstate?.selectedConv
  c = conv[conv_id]
  div class:'headwrap', ->
    return if not c # region cannot take undefined
    name = nameofconv c
    active = conv.lastActive(c)

    if updateActiveTimer?
      clearInterval updateActiveTimer

    # Update the active label every 10 seconds
    if active != 0
      updateActiveTimer = setInterval () ->
        el = document.querySelector('.namewrapper > .active')
        if el?
          active = parseInt el.getAttribute('active')
          el.innerHTML = i18n.__('conversation.active:Active %s', moment(active).fromNow()) if active != 0
      , 10 * 1000

    div class:'namewrapper', ->
        span class:'name', ->
          if conv.isQuiet(c)
                span class:'material-icons', 'notifications_off'
          if conv.isStarred(c)
            span class:'material-icons', "star"
          name
        span class:'active', active:active, i18n.__('conversation.active:Active %s', moment(active).fromNow()) if active != 0

    div class:"optionwrapper", ->
      div class:'button'
      , title: i18n.__('conversation.options:Conversation Options')
      , onclick:convoptions, -> span class:'material-icons', 'more_vert'
      div class:'convoptions'
      , title:i18n.__('conversation.settings:Conversation settings'), ->
          div class:'button'
          , title: i18n.__('menu.view.notification.toggle:Toggle notifications')
          , onclick:onclickaction('togglenotif')
          , ->
              if conv.isQuiet(c)
                  span class:'material-icons', 'notifications_off'
              else
                  span class:'material-icons', 'notifications'
              div class:'option-label', i18n.__n('notification:Notification', 1)
          div class:'button'
          , title:i18n.__('favorite.star_it:Star / unstar')
          , onclick:onclickaction('togglestar')
          , ->
              if not conv.isStarred(c)
                  span class:'material-icons', 'star_border'
              else
                  span class:'material-icons', 'star'
              div class:'option-label', i18n.__n('favorite.title:Favorite',1)
          div class:'button'
          , title:i18n.__('settings:Settings')
          , onclick:onclickaction('convsettings')
          , ->
              span class:'material-icons', 'info_outline'
              div class:'option-label', i18n.__('details:Details')
    if process.platform is 'win32'
        div class:"win-buttons", ->
            div class:'button', ->
                button id: "win-minimize"
                , title:i18n.__('window.controls:Minimize')
                , onclick: onclickaction('minimize')
            div class:'button', ->
                button id: "win-maximize"
                , title:i18n.__('window.controls:Maximize')
                , onclick: onclickaction('resizewindow')
            div class:'button', ->
                button id: "win-restore"
                , title:i18n.__('window.controls:Restore')
                , onclick: onclickaction('resizewindow')
            div class:'button', ->
                button id: "win-close"
                , title:i18n.__('window.controls:Close')
                , onclick: onclickaction('close')

ipc.on 'on-mainwindow.maximize', () ->
    toggleHidden document.getElementById('win-maximize'), true
    toggleHidden document.getElementById('win-restore'), false

ipc.on 'on-mainwindow.unmaximize', () ->
    toggleHidden document.getElementById('win-maximize'), false
    toggleHidden document.getElementById('win-restore'), true

toggleHidden = (element, hidden) ->
    return unless element
    if hidden
        element.style.display = 'none'
    else
        element.style.display = 'inline'

document.querySelector('body').addEventListener 'click', (event) ->
  if not document.querySelector('.optionwrapper').contains(event.target)
    document.querySelector('.convoptions').classList.remove('open')

convoptions  = ->
  {viewstate} = models
  document.querySelector('.convoptions').classList.toggle('open');
  if viewstate.state == viewstate.STATE_ADD_CONVERSATION
    action 'saveconversation'
