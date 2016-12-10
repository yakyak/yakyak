
# some unused icons/actions
#    {icon:'icon-user-add', action:'adduser'}
#    {icon:'icon-pencil',   action:'renameconv'}
#    {icon:'icon-videocam', action:'videocall'}
#    {icon:'icon-phone',    action:'voicecall'}

onclickaction = (a) -> (ev) -> action a

module.exports = view (models) ->
    {conv, viewstate} = models
    c = conv[viewstate.selectedConv]
    div class:'controls', ->
        div class:'button', title: i18n.__('Add new conversation'),
            onclick:onclickaction('addconversation'), -> span class:'material-icons', 'add'
