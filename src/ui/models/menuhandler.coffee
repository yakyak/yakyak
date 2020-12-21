{ Menu } = require('electron')

menuaction = (mainWindow, it) -> 
    if it.action.params?
        it.action.params.forEach (p) ->
            p = it.checked if p is ':checked'
            p = it.value if p is ':value'

        mainWindow.webContents.send 'menuaction', it.action.name, ...it.action.params
    else
        mainWindow.webContents.send 'menuaction', it.action.name

processMenu = (mainWindow, template) =>
    (template ? []).forEach (e) ->
        if e.submenu?
            processMenu mainWindow, e.submenu
            return

        if not e.action?
            return

        e.click = (it) ->
            menuaction mainWindow, it

module.exports = (mainWindow, template) ->
    processMenu mainWindow, template

    Menu.buildFromTemplate template