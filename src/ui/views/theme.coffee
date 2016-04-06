module.exports = view (viewstate) ->
    div ->
      link rel:"stylesheet", href: "#{viewstate.theme}.css"
