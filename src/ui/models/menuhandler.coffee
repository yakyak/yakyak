{ Menu } = require('electron')

menuaction = (mainWindow, it) -> 
    if it.action.params?
        params = it.action.params.map (p) ->
            if p is ':checked'
                it.checked
            if p is ':value'
                it.value
            else
                p

        console.error('menuaction', it.action.name, params...)

        mainWindow.webContents.send 'menuaction', it.action.name, params
    else
        console.error('menuaction', it.action.name)
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