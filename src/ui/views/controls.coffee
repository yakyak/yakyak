
convcontrols = [
    {icon:'icon-user-add', action:'adduser'}
    {icon:'icon-pencil',   action:'renameconv'}
#    {icon:'icon-videocam', action:'videocall'}
#    {icon:'icon-phone',    action:'voicecall'}
    {icon:'icon-cancel',   action:'removeconv'}
]

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
        convcontrols.forEach (c) ->
            div class:'button', onclick:onclickaction(c.action), -> span class:c.icon
        div class:'fill'
        div class:'button', onclick:onclickaction('addconversation'), -> span class:'icon-plus'
