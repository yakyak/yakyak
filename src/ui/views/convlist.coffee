{nameof} = require './vutil'

module.exports = view (models) ->
    {conv, entity} = models
    div class:'convlist', ->
        conv.list().forEach (conv) ->
            clz = ['conv']
            clz.push "type_#{conv.type}"
            div class:clz.join(' '), ->
                if conv.name?
                    conv.name
                else
                    # all entities in conversation that is not self
                    ents = for p in conv.current_participant when not entity.isSelf p.chat_id
                        entity[p.chat_id]
                    # the names of those entities
                    names = ents.map nameof
                    # joined together in a compelling manner
                    names.join ', '
