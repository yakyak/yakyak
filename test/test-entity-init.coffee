init   = require './init.json'
entity = require '../src/ui/models/entity'

describe 'entity', ->

    beforeEach ->
        entity._reset()

    describe 'initFromEntities', ->

        it 'populates lookup', ->
            added = entity._initFromEntities init.entities
            eql 2, added
            eql 2, entity.count()
            ent = entity['12230235892']
            assert.isNotNull ent
            eql 'Bo André Tenström', ent.display_name

    describe 'initFromSelfEntity', ->

        it 'adds entity to lookup', ->
            e = entity._initFromSelfEntity init.self_entity
            assert.isNotNull e
            assert 'Martin Algesten', e.display_name
            assert.strictEqual e, entity['10964681753']

        it 'adds entity as .self', ->
            e = entity._initFromSelfEntity init.self_entity
            assert.isNotNull e
            assert 'Martin Algesten', e.display_name
            assert.strictEqual e, entity.self

        it 'ensures isSelf works', ->
            entity._initFromSelfEntity init.self_entity
            eql true, entity.isSelf '10964681753'

        it 'keeps the self entity even if merged', ->
            entity._initFromSelfEntity init.self_entity
            entity.add {
                id: {gaia_id:'10964681753', chat_id:'10964681753'}
                testing: 'panda'
            }
            e = entity['10964681753']
            assert.isNotNull e
            eql 'Martin Algesten', e.display_name
            eql 'panda', e.testing
            assert.isTrue entity.isSelf '10964681753'
