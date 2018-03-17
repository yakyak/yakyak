{ MessageActionType } = require 'hangupsjs'
viewstate = require '../src/ui/models/viewstate'
userinput = require '../src/ui/models/userinput'
require('jsdom-global')()

describe 'userinput', ->

    describe 'buildChatMessage', ->

        it 'takes a text and does good', ->
            sender = { firstName: 'John' }
            viewstate.selectedConv = 'c123'
            msg = userinput.buildChatMessage sender, 'foo'
            eql msg.conv_id, 'c123'
            eql msg.image_id, undefined
            eql msg.message_action_type, [[MessageActionType.NONE, '']]
            eql msg.segs, [[0,'foo']]
            eql msg.segsj, [{text:'foo', type:'TEXT'}]
            assert.isNotNull msg.client_generated_id
            assert.isNotNull msg.ts
            eql msg.otr, 2

        it 'recognizes /me messages', ->
            sender = { first_name: 'John' }
            msg = userinput.buildChatMessage sender, '/me says hello'
            eql msg.message_action_type, [[MessageActionType.ME_ACTION, '']]
            eql msg.segs, [[0,'John says hello']]
            eql msg.segsj, [{text:'John says hello', type:'TEXT'}]

    describe 'parse', ->

        mb = null
        coll = ""
        beforeEach ->
            coll = ""
            mb = {
                text: spy -> coll += "t"
                link: spy -> coll += "l"
                linebreak: spy -> coll += "n"
            }

        it 'does text', ->
            userinput.parse mb, 'foo'
            eql mb.text.args, [['foo',false,false,false,false]]
            eql coll, 't'

        it 'does text with whitespace', ->
            userinput.parse mb, '  <br> <br> foo'
            eql mb.text.args, [['  ',false,false,false,false],[' ',false,false,false,false],[' foo',false,false,false,false]]
            eql mb.linebreak.args, [[],[]]
            eql coll, 'tntnt'

        it 'does \\n linebreaks', ->
            userinput.parse mb, 'foo<br>bar'
            eql mb.linebreak.args, [[]]
            eql mb.text.args, [['foo',false,false,false,false],['bar',false,false,false,false]]
            eql coll, 'tnt'

        it 'does \\r\\n linebreaks', ->
            userinput.parse mb, 'foo<br>bar'
            eql mb.linebreak.args, [[]]
            eql mb.text.args, [['foo',false,false,false,false],['bar',false,false,false,false]]
            eql coll, 'tnt'

        it 'does not ignore last linebreak', ->
            userinput.parse mb, 'foo<br>'
            eql mb.text.args, [['foo',false,false,false,false]]
            eql mb.linebreak.args, [[]]
            eql coll, 'tn'

        it 'does not ignore many last linebreak', ->
            userinput.parse mb, 'foo  <br><br><br>'
            eql mb.text.args, [['foo  ',false,false,false,false]]
            eql mb.linebreak.args, [[],[],[]]
            eql coll, 'tnnn'

        it 'identifies links only', ->
            userinput.parse mb, 'http://www.abc.com'
            eql mb.link.args, [['http://www.abc.com','http://www.abc.com']]
            eql coll, 'l'

        it 'finds links in text', ->
            userinput.parse mb, 'a http://www.abc.com b'
            eql mb.text.args, [['a ',false,false,false,false],[' b',false,false,false,false]]
            eql mb.link.args, [['http://www.abc.com','http://www.abc.com']]
            eql coll, 'tlt'

        it 'finds multiple links in text', ->
            userinput.parse mb, 'a http://www.abc.com b https://foo.bar c'
            eql mb.text.args, [['a ',false,false,false,false],[' b ',false,false,false,false],[' c',false,false,false,false]]
            eql mb.link.args, [['http://www.abc.com','http://www.abc.com'],
                ['https://foo.bar','https://foo.bar']]
            eql coll, 'tltlt'
