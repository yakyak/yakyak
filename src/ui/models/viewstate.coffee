Client = require 'hangupsjs'
ipc = require('electron').ipcRenderer

merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t

{throttle, later, tryparse, autoLauncher} = require '../util'

STATES =
    STATE_INITIAL: 'initial'
    STATE_NORMAL: 'normal'
    STATE_ADD_CONVERSATION: 'add_conversation'
    STATE_ABOUT: 'about'

module.exports = exp = {
    state: null
    startup: true
    attop: false   # tells whether message list is scrolled to top
    atbottom: true # tells whether message list is scrolled to bottom
    selectedConv: localStorage.selectedConv
    lastActivity: null
    leftSize: tryparse(localStorage.leftSize) ? 240
    size: tryparse(localStorage.size) ? [940, 600]
    pos: tryparse(localStorage.pos) ? [100, 100]
    showConvMin: tryparse(localStorage.showConvMin) ? false
    showConvThumbs: tryparse(localStorage.showConvThumbs) ? true
    showAnimatedThumbs: tryparse(localStorage.showAnimatedThumbs) ? true
    showConvTime: tryparse(localStorage.showConvTime) ? true
    showConvLast: tryparse(localStorage.showConvLast) ? true
    showPopUpNotifications: tryparse(localStorage.showPopUpNotifications) ? true
    showMessageInNotification: tryparse(localStorage.showMessageInNotification) ? true
    showUsernameInNotification: tryparse(localStorage.showUsernameInNotification) ? true
    convertEmoji: tryparse(localStorage.convertEmoji) ? true
    suggestEmoji: tryparse(localStorage.suggestEmoji) ? true
    showImagePreview: tryparse(localStorage.showImagePreview) ? true
    colorScheme: localStorage.colorScheme or 'default'
    fontSize: localStorage.fontSize or 'medium'
    zoom: tryparse(localStorage.zoom) ? 1.0
    loggedin: false
    escapeClearsInput: tryparse(localStorage.escapeClearsInput) or false
    showtray: tryparse(localStorage.showtray) or false
    hidedockicon: tryparse(localStorage.hidedockicon) or false
    colorblind: tryparse(localStorage.colorblind) or false
    startminimizedtotray: tryparse(localStorage.startminimizedtotray) or false
    closetotray: tryparse(localStorage.closetotray) or false
    showDockOnce: true
    showIconNotification: tryparse(localStorage.showIconNotification) ? true
    bouncyIcon: tryparse(localStorage.bouncyIcon) ? true
    muteSoundNotification: tryparse(localStorage.muteSoundNotification) ? false
    forceCustomSound: tryparse(localStorage.forceCustomSound) ? false
    language: localStorage.language ? 'en'
    useSystemDateFormat: localStorage.useSystemDateFormat is "true"
    spellcheckLanguage: localStorage.spellcheckLanguage ? 'none'
    # non persistent!
    messageMemory: {}      # stores input when swithching conversations
    cachedInitialsCode: {} # code used for colored initials, if no avatar
    # contacts are loaded
    loadedContacts: false
    openOnSystemStartup: false
    allDisplays: {}
    winSize: {}

    setUseSystemDateFormat: (val) ->
        @useSystemDateFormat = val
        localStorage.useSystemDateFormat = val
        updated 'language'

    setContacts: (state) ->
        return if state == @loadedContacts
        @loadedContacts = state
        @updateView()

    setState: (state) ->
        if state == STATES.STATE_INITIAL
            @startup = true

        return if @state == state
        @state = state
        if @startup
            # set a first active timestamp to avoid requesting
            # syncallnewevents on startup
            require('./connection').setLastActive(Date.now(), true)
        @updateView()

    setSpellCheckLanguage: (language) ->
        return if @language == language
        ipc.send 'spellcheck:setlanguage', language
        @spellcheckLanguage = localStorage.spellcheckLanguage = language
        @updateView()

    setLanguage: (language) ->
        return if @language == language
        i18n.locale = language
        i18n.setLocale(language)
        @language = localStorage.language = language
        updated 'language'

    switchInput: (next_conversation_id) ->
        # if conversation is changing, save input
        el = document.getElementById('message-input')
        if !el?
            console.debug 'Warning: could not retrieve message input to store.'
            return
        # save current input
        @messageMemory[@selectedConv] = el.value
        # either reset or fetch previous input of the new conv
        if @messageMemory[next_conversation_id]?
            el.value = @messageMemory[next_conversation_id]
            # once old conversation is retrieved memory is wiped
            @messageMemory[next_conversation_id] = ""
        else
            el.value = ''
        #

    setSelectedConv: (c) ->
        conv = require './conv' # circular
        conv_id = c?.conversation_id?.id ? c?.id ? c
        unless conv_id
            conv_id = conv.listShow()?[0]?.conversation_id?.id
        return if @selectedConv == conv_id
        @switchInput(conv_id)
        # don't save the selected conv if we don't have a valid input
        if c?
            @selectedConv = localStorage.selectedConv = conv_id
        @setLastKeyDown 0
        @updateView()
        updated 'switchConv'

    selectNextConv: (offset = 1) ->
        conv = require './conv'
        id = @selectedConv
        c = conv[id]
        list = conv.listShow()
        for c, index in list
            if id == c.conversation_id.id
                candidate = index + offset
                @setSelectedConv list[candidate] if list[candidate]

    selectConvIndex: (index = 0) ->
        conv = require './conv'
        list = conv.listShow()
        @setSelectedConv list[index] if index < list.length

    updateAtTop: (attop) ->
        return if @attop == attop
        @attop = attop
        @updateView()

    updateAtBottom: (atbottom) ->
        return if @atbottom == atbottom
        @atbottom = atbottom
        @updateActivity Date.now()

    updateActivity: (time) ->
        conv = require './conv' # circular
        @lastActivity = time
        later -> action 'lastActivity'
        return unless document.hasFocus() and @atbottom and @state == STATES.STATE_NORMAL
        c = conv[@selectedConv]
        return unless c
        ur = conv.unread c
        # send updatewatermark if this is the first update, even if we have no unread messages
        if ur > 0 or not c.watermark_updated?
            c.watermark_updated = true
            later -> action 'updatewatermark'

    setSize: (size) ->
        return if @startup
        localStorage.size = JSON.stringify(size)
        @size = size
        # @updateView()

    setPosition: (pos) ->
        return if @startup
        localStorage.pos = JSON.stringify(pos)
        @pos = pos
        # @updateView()

    setLeftSize: (size) ->
        return if @startup or @leftSize == size or size < 180
        @leftSize = localStorage.leftSize = size
        @updateView()

    setZoom: (zoom) ->
        @zoom = localStorage.zoom = document.body.style.zoom = zoom
        document.body.style.setProperty('--zoom', zoom)

    setLoggedin: (val) ->
        @loggedin = val
        @updateView()

    setShowSeenStatus: (val) ->
        @showseenstatus = localStorage.showseenstatus = !!val
        @updateView()

    setLastKeyDown: do ->
        {TYPING, PAUSED, STOPPED} = Client.TypingStatus
        lastEmitted = 0
        timeout = 0
        update = throttle 500, (time) ->
            clearTimeout timeout if timeout
            timeout = null
            unless time
                lastEmitted = 0
            else
                if time - lastEmitted > 5000
                    later -> action 'settyping', TYPING
                    lastEmitted = time
                timeout = setTimeout ->
                    # after 6 secods of no keyboard, we consider the
                    # user took a break.
                    lastEmitted = 0
                    action 'settyping', PAUSED
                    timeout = setTimeout ->
                        # and after another 6 seconds (12 total), we
                        # consider the typing stopped altogether.
                        action 'settyping', STOPPED
                    , 6000
                , 6000

    setShowConvMin: (doshow) ->
        return if @showConvMin == doshow
        @showConvMin = localStorage.showConvMin = doshow
        if doshow
            this.setShowConvThumbs(true)
        @updateView()

    setShowConvThumbs: (doshow) ->
        return if @showConvThumbs == doshow
        @showConvThumbs = localStorage.showConvThumbs = doshow
        unless doshow
            this.setShowConvMin(false)
        @updateView()

    setShowAnimatedThumbs: (doshow) ->
        return if @showAnimatedThumbs == doshow
        @showAnimatedThumbs = localStorage.showAnimatedThumbs = doshow
        @updateView()

    setShowConvTime: (doshow) ->
        return if @showConvTime == doshow
        @showConvTime = localStorage.showConvTime = doshow
        @updateView()

    setShowConvLast: (doshow) ->
        return if @showConvLast == doshow
        @showConvLast = localStorage.showConvLast = doshow
        @updateView()

    setShowPopUpNotifications: (doshow) ->
        return if @showPopUpNotifications == doshow
        @showPopUpNotifications = localStorage.showPopUpNotifications = doshow
        @updateView()

    setShowMessageInNotification: (doshow) ->
        return if @showMessageInNotification == doshow
        @showMessageInNotification = localStorage.showMessageInNotification = doshow
        @updateView()

    setShowUsernameInNotification: (doshow) ->
        return if @showUsernameInNotification == doshow
        @showUsernameInNotification = localStorage.showUsernameInNotification = doshow
        @updateView()

    setForceCustomSound: (doshow) ->
        return if localStorage.forceCustomSound == doshow
        @forceCustomSound = localStorage.forceCustomSound = doshow
        @updateView()

    setBouncyIcon: (doshow) ->
        return if localStorage.bouncyIcon == doshow
        @bouncyIcon = localStorage.bouncyIcon = doshow
        updated 'viewstate'

    setShowIconNotification: (doshow) ->
        return if localStorage.showIconNotification == doshow
        @showIconNotification = localStorage.showIconNotification = doshow
        @updateView()

    setMuteSoundNotification: (doshow) ->
        return if localStorage.muteSoundNotification == doshow
        @muteSoundNotification = localStorage.muteSoundNotification = doshow
        @updateView()

    setConvertEmoji: (doshow) ->
        return if @convertEmoji == doshow
        @convertEmoji = localStorage.convertEmoji = doshow
        @updateView()

    setSuggestEmoji: (doshow) ->
        return if @suggestEmoji == doshow
        @suggestEmoji = localStorage.suggestEmoji = doshow
        @updateView()

    setshowImagePreview: (doshow) ->
        return if @showImagePreview == doshow
        @showImagePreview = localStorage.showImagePreview = doshow
        @updateView()

    setColorScheme: (colorscheme) ->
        ipc.send 'colorscheme:set', colorscheme
        @colorScheme = localStorage.colorScheme = colorscheme
        document.querySelector('html').setAttribute 'theme', @colorScheme

    setFontSize: (fontsize) ->
        @fontSize = localStorage.fontSize = fontsize
        document.querySelector('html').setAttribute 'font-size', @fontSize

    setEscapeClearsInput: (value) ->
        @escapeClearsInput = localStorage.escapeClearsInput = value
        @updateView()

    setColorblind: (value) ->
        @colorblind = localStorage.colorblind = value
        @updateView()

    setShowTray: (value) ->
        @showtray = localStorage.showtray = value

        if not @showtray
            @setCloseToTray(false)
            @setStartMinimizedToTray(false)
        else
            @updateView()

    setHideDockIcon: (value) ->
        @hidedockicon = localStorage.hidedockicon = value
        @updateView()

    setStartMinimizedToTray: (value) ->
        @startminimizedtotray = localStorage.startminimizedtotray = value
        @updateView()

    setShowDockIconOnce: (value) ->
        @showDockIconOnce = value

    setCloseToTray: (value) ->
        @closetotray = localStorage.closetotray = !!value
        @updateView()

    setOpenOnSystemStartup: (open) ->
        return if @openOnSystemStartup == open

        if open
            autoLauncher.enable()
        else
            autoLauncher.disable()

        @openOnSystemStartup = open

        @updateView()

    initOpenOnSystemStartup: (isEnabled) ->
        @openOnSystemStartup = isEnabled

        @updateView()

    updateView: () ->
        @allDisplays = await ipc.invoke 'screen:getalldisplays'
        @winSize = await ipc.invoke 'mainwindow:getsize'

        # the awaits above means this function will be async,
        # so we can't trigger the 'updated' action directly from here
        action 'viewstate_updated'

    startupDone: () ->
        @startup = false
}

merge exp, STATES
