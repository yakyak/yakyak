module.exports = exp = {
    # Current models are dedicated to 'add conversation' functionality
    # but we plan to make this more generic
    searchedEntities: []
    selectedEntities: []

    setSearchedEntities: (entities) ->
        @searchedEntities = entities
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

    setSelectedEntities: (entities) -> @selectedEntities = entities # no need to update
}

