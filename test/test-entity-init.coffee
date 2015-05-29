init   = require './init.json'
entity = require '../src/ui/models/entity'

describe 'entity', ->

    beforeEach ->
        entity._reset()

    describe 'initFromEntities', ->

        it 'populates lookup', ->
            added = entity._initFromEntities init.entities
            eql 57, added
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

    describe 'count', ->

        it 'counts total', ->
            added = entity._initFromEntities init.entities
            eql 57, added
            eql added, entity.count()
