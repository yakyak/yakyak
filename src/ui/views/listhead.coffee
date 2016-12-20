module.exports = view (models) ->
	div class:'listheadlabel', ->
		if process.platform isnt 'darwin'
			button title: i18n.__('menu.title:Menu'), onclick: togglemenu, ->
				i class:'material-icons', "menu"
		span i18n.__n("conversation.title:Conversations", 2)

togglemenu = ->
	if process.platform isnt 'darwin'
		action 'togglemenu'
