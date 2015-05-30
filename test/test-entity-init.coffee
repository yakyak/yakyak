init   = require './init.json'
entity = require '../src/ui/models/entity'

describe 'entity', ->

    beforeEach ->
        entity._reset()

    describe 'initFromEntities', ->

        it 'populates lookup', ->
            added = entity._initFromEntities init.entities
            eql 57, added
            eql 57, entity.count()
            ent = entity['110003046983028707939']
            assert.isNotNull ent
            eql 'Inge Mandersson', ent.display_name

    describe 'initFromSelfEntity', ->

        it 'adds entity to lookup', ->
            e = entity._initFromSelfEntity init.self_entity
            assert.isNotNull e
            assert 'Martin Algesten', e.display_name
            assert.strictEqual e, entity['110994664963851875523']

        it 'adds entity as .self', ->
            e = entity._initFromSelfEntity init.self_entity
            assert.isNotNull e
            assert 'Martin Algesten', e.display_name
            assert.strictEqual e, entity.self

        it 'ensures isSelf works', ->
            entity._initFromSelfEntity init.self_entity
            entity.isSelf '110994664963851875523'

        it 'keeps the self entity even if merged', ->
            entity._initFromSelfEntity init.self_entity
            entity.add {
                id: {gaia_id:'110994664963851875523', chat_id:'110994664963851875523'}
                testing: 'panda'
            }
            e = entity['110994664963851875523']
            assert.isNotNull e
            eql 'Martin Algesten', e.display_name
            eql 'panda', e.testing
            assert.isTrue entity.isSelf '110994664963851875523'

    describe 'count', ->

        it 'counts total', ->
            added = entity._initFromEntities init.entities
            eql 57, added
            eql added, entity.count()
