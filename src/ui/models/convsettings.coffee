entity = require './entity'

module.exports = exp = {
    # Current models are dedicated to 'add conversation' functionality
    # but we plan to make this more generic
    searchedEntities: []
    selectedEntities: []
    name: ""
    searchQuery: ""
    id: null

    setSearchedEntities: (entities) ->
        @searchedEntities = entities or []
        updated 'searchedentities'

    addSelectedEntity: (entity) ->
        id = entity.id?.chat_id or entity # may pass id directly
        exists = (e for e in @selectedEntities when e.id.chat_id == id).length != 0
        if not exists
          @selectedEntities.push entity
          updated 'selectedEntities'

    removeSelectedEntity: (entity) ->
        id = entity.id?.chat_id or entity # may pass id directly
        @selectedEntities = (e for e in @selectedEntities when e.id.chat_id != id)
        updated 'selectedEntities'

    setSelectedEntities: (entities) -> @selectedEntities = entities or [] # no need to update

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
      @id = c.conversation_id or c.id
      @name = c.name or ""
      updated 'convsettings'

    reset: ->
      @searchedEntities = []
      @selectedEntities = []
      @searchQuery = ""
      @name = ""
      @id = null
      updated 'convsettings'


}

