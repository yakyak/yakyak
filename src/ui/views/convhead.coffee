{nameofconv}  = require '../util'

onclickaction = (a) -> (ev) -> action a

module.exports = view (models) ->
  {conv, viewstate} = models
  conv_id = viewstate?.selectedConv
  c = conv[conv_id]
  return if not c
  name = nameofconv c
  div class:'headwrap', ->
    span class:'name', ->
      if conv.isQuiet(c)
            span class:'material-icons', 'notifications_off'
      if conv.isStarred(c)
        span class:'material-icons', "star"
      name
    div class:'button', title: i18n.__('Conversation options'),
      onclick:convoptions, -> span class:'material-icons', 'more_vert'
    div class:'convoptions', ->
      div class:'button', title:i18n.__('Conversation settings'),
        div class:'button', title: i18n.__('Toggle notifications'), onclick:onclickaction('togglenotif'), ->
                if conv.isQuiet(c)
                    span class:'material-icons', 'notifications_off'
                else
                    span class:'material-icons', 'notifications'
                div class:'option-label', i18n.__('Notifications')
            div class:'button', title:i18n.__('Star/unstar'), onclick:onclickaction('togglestar'), ->
                  if not conv.isStarred(c)
                    span class:'material-icons', 'star_border'
                  else
                    span class:'material-icons', 'star'
                  div class:'option-label', i18n.__('Favorite')
              div class:'button', title:i18n.__('Settings'),
          onclick:onclickaction('convsettings'), ->
            span class:'material-icons', 'info_outline'
            div class:'option-label', i18n.__('Details')

convoptions  = ->
  {viewstate} = models
  document.querySelector('.convoptions').classList.toggle('open');
  if viewstate.state == viewstate.STATE_ADD_CONVERSATION
    action 'saveconversation'
