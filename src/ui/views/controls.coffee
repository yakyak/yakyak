
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
        div class:'button', onclick:onclickaction('togglenotif'), ->
            if conv.isQuiet(c)
                span class:'icon-bell-off-empty'
            else
                span class:'icon-bell'
        div class:'button', onclick:onclickaction('convsettings'), -> span class:'icon-cog'
        if c?.type?.indexOf('ONE_TO_ONE') > 0
            div class:'button', onclick:onclickaction('deleteconv'), -> span class:'icon-cancel'
        else
            div class:'button', onclick:onclickaction('leaveconv'), -> span class:'icon-cancel'
        div class:'fill'
        div class:'button', onclick:onclickaction('addconversation'), -> span class:'icon-plus'
