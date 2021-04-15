entity = require './entity'

module.exports = exp = {
    # This handles the data of conversation add / edit
    # where you can specify participants conversation name, etc
    searchedEntities: []
    selectedEntities: []
    initialName: null
    initialSearchQuery: null
    name: ""
    searchQuery: ""
    id: null
    group: false

    setSearchedEntities: (entities) ->
        @searchedEntities = entities or []
        updated 'searchedentities'

    addSelectedEntity: (entity) ->
        id = entity.id?.chat_id or entity # may pass id directly
        exists = (e for e in @selectedEntities when e.id.chat_id == id).length != 0
        if not exists
            @selectedEntities.push entity
            @group = @selectedEntities.length > 1
            updated 'convsettings'

    removeSelectedEntity: (entity) ->
        id = entity.id?.chat_id or entity # may pass id directly
        # if the conversation we are editing is one to one we don't want
        # to remove the selected entity
        @selectedEntities = (e for e in @selectedEntities when e.id.chat_id != id)
        @group = @selectedEntities.length > 1
        updated 'selectedEntities'

    setSelectedEntities: (entities) ->
        @group = entities.length > 1
        @selectedEntities = entities or [] # no need to update
    
    setGroup: (val) -> @group = val; updated 'convsettings'

    setInitialName: (name) -> @initialName = name
    getInitialName: -> v = @initialName; @initialName = null; v

    setInitialSearchQuery: (query) -> @initialSearchQuery = query
    getInitialSearchQuery: -> v = @initialSearchQuery; @initialSearchQuery = null; v

    setName: (name) -> @name = name

    setSearchQuery: (query) -> @searchQuery = query
    
    loadConversation: (c) ->
        c.participant_data.forEach (p) =>
            id = p.id.chat_id or p.id.gaia_id
            if entity.isSelf id then return
            p = entity[id]
            @selectedEntities.push
                id: chat_id: id
                properties:
                    photo_url: p.photo_url
                    display_name: p.display_name or p.fallback_name
        @group = @selectedEntities.length > 1
        @id = c.conversation_id?.id or c.id?.id
        @initialName = @name = c.name or ""
        @initialSearchQuery = ""
        
        updated 'convsettings'

    reset: ->
        @searchedEntities = []
        @selectedEntities = []
        @initialName = ""
        @initialSearchQuery = ""
        @searchQuery = ""
        @name = ""
        @id = null
        @group = false
        updated 'convsettings'


}

