Client = require 'hangupsjs'
settings = require('node-persist')

{throttle, later, tryparse, autoLauncher} = require '../util'

settings.initSync()

module.exports = exp = {
    setSize: (size) ->
        settings.setItemSync('size', JSON.stringify(size))

    setPosition: (pos) ->
        settings.setItemSync('pos', JSON.stringify(pos))

    getBounds: () ->
        size = tryparse(settings.getItemSync('size') ? "[940, 600]")
        pos = tryparse(settings.getItemSync('pos') ? "[100, 100]")
        return {x: pos[0], y: pos[1], width: size[0], height: size[1]}
}
