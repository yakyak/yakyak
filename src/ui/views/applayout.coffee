module.exports = layout ->
    div class:'applayout', ->
        div class:'row', ->
            div class:'left span3', region('left')
            div class:'main span9', region('main')
