{nameofconv}  = require '../util'

onclickaction = (a) -> (ev) -> action a

module.exports = view (models) ->
  {conv, viewstate} = models
  conv_id = viewstate?.selectedConv
  c = conv[conv_id]
  div class:'headwrap', ->
    return if not c # region cannot take undefined
    name = nameofconv c
    span class:'name', ->
      if conv.isQuiet(c)
            span class:'material-icons', 'notifications_off'
      if conv.isStarred(c)
        span class:'material-icons', "star"
      name
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

convoptions  = ->
  {viewstate} = models
  document.querySelector('.convoptions').classList.toggle('open');
  if viewstate.state == viewstate.STATE_ADD_CONVERSATION
    action 'saveconversation'
