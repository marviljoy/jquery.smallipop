###!
Smallipop (09/28/2012)
Copyright (c) 2011-2012 Small Improvements (http://www.small-improvements.com)

Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.

@author Sebastian Helzle (sebastian@helzle.net)
###

(($) ->
  $.smallipop =
    version: '0.2.0-alpha'
    defaults:
      popupOffset: 31
      popupYOffset: 0
      popupDistance: 20
      popupDelay: 100
      windowPadding: 30 # Imaginary padding in viewport
      hideTrigger: false
      theme: 'default'
      infoClass: 'smallipopHint'
      triggerAnimationSpeed: 150
      popupAnimationSpeed: 200
      invertAnimation: false
      horizontal: false
      preferredPosition: 'top' # bottom, top, left or right
      triggerOnClick: false
      touchSupport: true
      funcEase: 'easeInOutQuad'
      onBeforeShow: null
      onAfterShow: null
      onBeforeHide: null
      onAfterHide: null
    popup: null
    lastId: 1 # Counter for new smallipop id's

    hideSmallipop: ->
      sip = $.smallipop
      shownId = sip.popup.data 'shown'

      # Show trigger if hidden before
      trigger = $ ".smallipop#{shownId}"
      triggerOpt = trigger.data('options') or sip.defaults
      trigger.stop(true).fadeTo(triggerOpt.triggerAnimationSpeed, 1) if shownId and triggerOpt.hideTrigger

      direction = if triggerOpt.invertAnimation then -1 else 1
      xDistance = sip.popup.data('xDistance') * direction
      yDistance = sip.popup.data('yDistance') * direction

      sip.popup
      .data
        hideDelayTimer: null
        beingShown: false
      .stop(true)
      .animate
          top: "-=#{xDistance}px"
          left: "+=#{yDistance}px"
          opacity: 0
        , triggerOpt.popupAnimationSpeed, triggerOpt.funcEase, ->
          # Hide tip if not being shown in the meantime
          tip = $ @
          tip.css('display', 'none').data('shown', '') unless tip.data 'beingShown'

          triggerOpt.onAfterHide?()


    _showSmallipop: (e) ->
      sip = $.smallipop
      e.preventDefault() if sip.popup.data('shown') isnt $(@).data('id')
      sip._triggerMouseover.call @

    onTouchDevice: ->
      return Modernizr?.touch

    killTimers: ->
      popup = $.smallipop.popup
      hideTimer = popup.data 'hideDelayTimer'
      showTimer = popup.data 'showDelayTimer'
      clearTimeout(hideTimer) if hideTimer
      clearTimeout(showTimer) if showTimer

    refreshPosition: () ->
      sip = $.smallipop
      popup = sip.popup
      shownId = popup.data 'shown'

      trigger = $ ".smallipop#{shownId}"
      options = trigger.data 'options'

      # Reset css classes for popup
      popup
        .removeClass()
        .addClass(options.theme)

      # Prepare some properties
      win = $ window
      xDistance = yDistance = options.popupDistance
      yOffset = options.popupYOffset

      # Get new dimensions
      offset = trigger.offset()

      popupH = popup.outerHeight()
      popupW = popup.outerWidth()
      popupCenter = popupW / 2

      winWidth = win.width()
      winHeight = win.height()
      windowPadding = options.windowPadding

      selfWidth = trigger.outerWidth()
      selfHeight = trigger.outerHeight()
      selfY = offset.top - win.scrollTop()

      popupOffsetLeft = offset.left + selfWidth / 2
      popupOffsetTop = offset.top - popupH + yOffset
      popupY = popupH + options.popupDistance - yOffset
      popupDistanceTop = selfY - popupY
      popupDistanceBottom = winHeight - selfY - selfHeight - popupY
      popupDistanceLeft = offset.left - popupW - options.popupOffset
      popupDistanceRight = winWidth - offset.left - selfWidth - popupW

      if options.horizontal
        xDistance = 0
        popupOffsetTop += selfHeight / 2 + popupH / 2
        if (options.preferredPosition is 'left' and popupDistanceLeft > windowPadding) or popupDistanceRight < windowPadding
          # Positioned left
          popup.addClass 'sipPositionedLeft'
          popupOffsetLeft = offset.left - popupW - options.popupOffset
          yDistance = -yDistance
        else
          # Positioned right
          popup.addClass 'sipPositionedRight'
          popupOffsetLeft = offset.left + selfWidth + options.popupOffset
      else
        yDistance = 0
        if popupOffsetLeft + popupCenter > winWidth - windowPadding
          # Aligned left
          popupOffsetLeft -= popupCenter * 2 - options.popupOffset
          popup.addClass 'sipAlignLeft'
        else if popupOffsetLeft - popupCenter < windowPadding
          # Aligned right
          popupOffsetLeft -= options.popupOffset
          popup.addClass 'sipAlignRight'
        else
          # Centered
          popupOffsetLeft -= popupCenter

        # Add class if positioned below
        if (options.preferredPosition is 'bottom' and popupDistanceBottom > windowPadding) or popupDistanceTop < windowPadding
          popupOffsetTop += popupH + selfHeight - 2 * yOffset
          xDistance = -xDistance
          yOffset = 0
          popup.addClass 'sipAlignBottom'

      # Hide trigger if defined
      if options.hideTrigger
        trigger
          .stop(true)
          .fadeTo(options.triggerAnimationSpeed, 0)

      # Animate to new position if refresh does no
      beingShown = popup.data 'beingShown'
      unless beingShown
        popupOffsetTop -= xDistance
        popupOffsetLeft += yDistance
        xDistance = 0
        yDistance = 0

      cssTarget =
        top: popupOffsetTop
        left: popupOffsetLeft
        display: 'block'
        opacity: if beingShown then 0 else 1

      animationTarget =
        top: "-=#{xDistance}px"
        left: "+=#{yDistance}px"
        opacity: 1

      # Start fade in animation
      popup
        .data
          xDistance: xDistance
          yDistance: yDistance
        .stop(true)
        .css(cssTarget)
        .animate animationTarget, options.popupAnimationSpeed, options.funcEase, ->
          if beingShown
            popup.data 'beingShown', false
            options.onAfterShow? trigger

    _getTrigger: (id) ->
      $ ".smallipop#{id}"

    _showPopup: (trigger) ->
      sip = $.smallipop
      popup = sip.popup

      return unless popup.data 'triggerHovered'

      # Get smallipop options stored in trigger and popup
      options = trigger.data 'options'
      hint = trigger.data 'hint'
      id = trigger.data 'id'
      shownId = popup.data 'shown'

      # Show last trigger if not yet visible
      lastTrigger = sip._getTrigger shownId
      lastTriggerOpt = lastTrigger.data('options') or sip.defaults
      if shownId and lastTriggerOpt.hideTrigger
        lastTrigger
          .stop(true)
          .fadeTo(lastTriggerOpt.fadeSpeed, 1)

      # Update tip content and remove all classes
      popup
        .data
          beingShown: true
          shown: id
        .find('.sipContent')
        .html(hint)

      sip.refreshPosition()

    _triggerMouseover: ->
      self = $ @
      id = self.data 'id'

      sip = $.smallipop
      popup = sip.popup
      shownId = popup.data 'shown'

      sip.killTimers()
      popup.data((if id then 'triggerHovered' else 'hovered'), true)

      unless id
        self = sip._getTrigger shownId
      options = self.data 'options'
      options.onBeforeShow? self

      if not popup.data('beingShown') and shownId isnt id
        popup.data 'showDelayTimer', setTimeout ->
            sip._showPopup self
          , options.popupDelay

    _triggerMouseout: ->
      self = $ @
      id = self.data 'id'

      sip = $.smallipop
      popup = sip.popup
      shownId = popup.data 'shown'

      sip.killTimers()
      popup.data((if id then 'triggerHovered' else 'hovered'), false)

      unless id
        self = sip._getTrigger shownId
      options = self.data 'options'
      options.onBeforeHide? self

      # Hide tip after a while
      unless popup.data('hovered') or popup.data('triggerHovered')
        popup.data('hideDelayTimer', setTimeout(sip.hideSmallipop, 500))

    _onWindowResize: ->
      $.smallipop.refreshPosition()

    _onWindowClick: (e) ->
      sip = $.smallipop
      popup = sip.popup
      # Hide smallipop unless popup or a trigger is clicked
      unless e.target is popup[0] or $(e.target).closest('.sipInitialized').length
        sip.hideSmallipop.call @

    setContent: (content) ->
      sip = $.smallipop

      sip.popup
        .find('.sipContent')
        .html(content)

      sip.refreshPosition()

  ### Add default easing function for smallipop to jQuery if missing ###
  unless $.easing.easeInOutQuad
    $.easing.easeInOutQuad = (x, t, b, c, d) ->
      if ((t/=d/2) < 1) then c/2*t*t + b else -c/2 * ((--t)*(t-2) - 1) + b

  $.fn.smallipop = (options={}, hint='') ->
    sip = $.smallipop
    options = $.extend {}, sip.defaults, options

    # Fix for some option deprecation issues
    options.popupAnimationSpeed = options.moveSpeed if options.moveSpeed?
    options.triggerAnimationSpeed = options.hideSpeed if options.hideSpeed?

    # Check whether the trigger should activate smallipop by click or hover
    triggerEvents = {}
    if options.triggerOnClick or (options.touchSupport and sip.onTouchDevice())
      triggerEvents =
        click: sip._showSmallipop
    else
      triggerEvents =
        mouseover: sip._triggerMouseover
        mouseout: sip._triggerMouseout
        click: sip.hideSmallipop

    # Initialize smallipop on first call
    popup = $ '#smallipop'
    unless popup.length
      popup = sip.popup = $("<div id=\"smallipop\"><div class=\"sipContent\"/><div class=\"sipArrowBorder\"/><div class=\"sipArrow\"/></div>")
      .css("opacity", 0)
      .data
        xDistance: 0
        yDistance: 0
      .bind
        mouseover: sip._triggerMouseover
        mouseout: sip._triggerMouseout

      $('body').append popup

      # Hide popup when clicking a contained link
      $('a', popup.get(0)).live 'click', sip.hideSmallipop

      $(document).bind 'click touchend', sip._onWindowClick

      $(window).bind 'resize', sip._onWindowResize

    return @.each ->
      # Initialize each trigger, create id and bind events
      self = $ @
      objHint = hint or self.attr('title') or self.find(".#{options.infoClass}").html()
      if objHint and not self.hasClass('sipInitialized')
        newId = sip.lastId++
        self
          .addClass("sipInitialized smallipop#{newId}")
          .data
            id: newId
            options: options
            hint: objHint
          .attr('title', '') # Remove title to disable browser hint
          .bind(triggerEvents)

        # Hide popup when links contained in the trigger are clicked
        $('a', @).live 'click', sip.hideSmallipop
)(jQuery)

