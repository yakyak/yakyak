Q = require 'q'

module.exports = class Config
    constructor: () ->
        @listeners = {}
        @idgen = 0
        @ipc = require 'ipc'
        @ipc.on "returngetconfig", (id, value) =>
            callback = @listeners[id]
            callback? value
            delete @listeners[id]

    get: (key) => Q.Promise (rs) =>
        id = @idgen++
        @ipc.send 'getconfig', id, key
        @listeners[id] = rs

    set: (key, value) =>
        @ipc.send 'setconfig', key, value
