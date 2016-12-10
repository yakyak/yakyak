module.exports = view (models) ->
	div class:'listheadlabel', ->
		if process.platform isnt 'darwin'
			button title: i18n.__ 'Menu', onclick: togglemenu, ->
				i class:'material-icons', "menu"
		span i18n.__("Conversations")

togglemenu = ->
	if process.platform isnt 'darwin'
		action 'togglemenu'
