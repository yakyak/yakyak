init   = require './init.json'
entity = require '../src/ui/models/entity'

describe 'entity', ->

    beforeEach ->
        entity._reset()

    describe 'count', ->

        it 'counts total', ->
            added = entity._initFromEntities init.entities
            eql 2, added
            eql added, entity.count()

    describe 'isSelf', ->

        it 'does not true for undefined self', ->
            eql entity.self, undefined
            eql false, entity.isSelf 'foo'

    describe 'add', ->

        it 'adds an .id prop which is the chat_id and returns the result', ->
            ret = entity.add {
                id:
                    chat_id:'a'
                    gaia_id:'b'
            }
            eql entity['a'], {
                id:'a'
            }
            assert.strictEqual ret, entity['a']

        it 'adds a gaia_id ref if not same as chat_id', ->
            entity.add {
                id:
                    chat_id:'a'
                    gaia_id:'b'
            }
            eql entity['b'], {
                id:'a'
            }

        it 'merges properties into the object', ->
            entity.add {
                id:
                    gaia_id:'a'
                    chat_id:'a'
                properties:
                    some:'prop'
            }
            eql entity['a'], {
                id:'a'
                some:'prop'
            }

        it 'merges all other props', ->
            entity.add {
                id:
                    gaia_id:'a'
                    chat_id:'a'
                some:'outer prop'
            }
            eql entity['a'], {
                id:'a'
                some:'outer prop'
            }

    describe 'needEntity', ->

        afterEach ->
            global.action = ->

        it 'gathers entity id during a timeout and does an action for all', (done) ->
            entity.needEntity 'a', 10
            entity.needEntity 'b', 10
            entity.needEntity 'c', 10
            global.action = (n, ids) ->
                eql n, 'getentity'
                eql ids, ['a','b','c']
                done()
