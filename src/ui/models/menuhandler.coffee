{ Menu } = require('electron')

menuaction = (mainWindow, it) ->
    params = (it.action.params ? []).map (p) ->
        if p is ':checked'
            it.checked
        else if p is ':value'
            it.value
        else
            p

    mainWindow.webContents.send 'menuaction', it.action.name, params

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