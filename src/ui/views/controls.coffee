
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
        div class:'button', title:'Toggle notifications', onclick:onclickaction('togglenotif'), ->
            if conv.isQuiet(c)
                span class:'icon-bell-off-empty'
            else
                span class:'icon-bell'
        div class:'button', title:'Star/unstar', onclick:onclickaction('togglestar'), ->
                if not conv.isStarred(c)
                   span class:'icon-star-empty'
                else
                     span class:'icon-star'
        div class:'button', title:'Conversation settings',
            onclick:onclickaction('convsettings'), -> span class:'icon-cog'
        if c?.type?.indexOf('ONE_TO_ONE') > 0
            div class:'button', title:'Delete conversation',
            onclick:onclickaction('deleteconv'), -> span class:'icon-cancel'
        else
            div class:'button', title:'Leave conversation',
            onclick:onclickaction('leaveconv'), -> span class:'icon-cancel'
        div class:'fill'
        div class:'button', title:'Add new conversation',
            onclick:onclickaction('addconversation'), -> span class:'icon-plus'
