Backbone = require 'backbone'
$ = require 'jquery'
_ = require 'underscore'

dom = require 'hilib/src/utils/dom'
require 'hilib/src/utils/jquery.mixin'

tpl = require '../templates/text.jade'

config = require '../../../models/config'
textlayers = require '../../../collections/textlayers'

hl = null

class EntryTextView extends Backbone.View

	className: 'text'

	# ### Initialize

	initialize: (@options) -> @render()

	# ### Render

	render: ->
		text = @options.paralleltexts[@options.textLayer]?.text

		# Doing this to ensure empty lines get correct height, so as not to mess with line numbering
		if text?
			text = String(text).replace /<div class="line">\s*<\/div>/mg, '<div class="line">&nbsp;</div>'

		@$el.html tpl 
			textLayer: @options.textLayer
			textlayers: textlayers
		# @$el.fadeOut(75).append(text).fadeIn(75)
		@$el.append(text)

		enter = (ev) => 
			markerId = ev.currentTarget.getAttribute 'data-id'
			@options.eventBus.trigger 'activate:annotation', markerId
			@highlightOn markerId
		leave = (ev) => 
			markerId = ev.currentTarget.getAttribute 'data-id'
			@options.eventBus.trigger 'unactivate:annotation', markerId
			@highlightOff markerId
		@$('sup[data-marker]').hover enter, leave

		@$el.addClass config.get('textFont')

		@

	# ### Events
	events:
		'change header select': 'changeTextlayer'
		# 'click i.btn-print': (e) -> window.print()
		'click i.toggle-annotations': 'toggleAnnotations'
		'click sup[data-marker]': 'toggleAnnotation'

	toggleAnnotations: (ev) ->
		target = $(ev.currentTarget)
		
		# If class is fa-comments, we are going to show the annotations (showing=true)
		showing = target.hasClass 'fa-comments'
		
		target.toggleClass 'fa-comments'
		target.toggleClass 'fa-comments-o'

		# Change the title attribute of the icon
		title = if showing then 'Hide annotations' else 'Show annotations'
		target.attr 'title', title

		# The event is picked up by the parent view to set a className, so we can hide the
		# annotations using CSS.
		@trigger 'toggle-annotations', showing

	toggleAnnotation: (ev) ->
		markerId = ev.currentTarget.getAttribute 'data-id'
		supTop = dom(ev.currentTarget).position(@el).top
		
		@options.eventBus.trigger 'toggle:annotation', markerId, supTop

	changeTextlayer: (ev) -> 
		ev = ev.currentTarget.options[ev.currentTarget.selectedIndex].value if ev.hasOwnProperty 'currentTarget'
		@trigger 'change:textlayer', ev

	# ### Methods

	destroy: -> @remove()


	highlightAnnotation: (markerId, $scrollEl) ->
		@highlightOn markerId

		$sup = @$ "sup[data-id='#{markerId}']"
		# console.log markerId, $sup, dom($sup[0]).position(), dom($sup[0]).position(@el).top

		@options.eventBus.trigger 'toggle:annotation', markerId, dom($sup[0]).position(@el).top
		
		@scrollIntoView $sup

	highlightTerms: (terms) ->
		for term in terms
			$divs = @$("div.line:contains(#{term})")

			for div in $divs
				$div = $(div)
				regex = new RegExp(term, "gi")
				html = $div.html().replace(regex, "<span class=\"highlight-term\">$&</span>")
				$div.html html

	# markTerm: (query) ->
	# 	$divs = @$("div.line:contains('#{query}')")
	# 	_.each $divs, (div) ->
	# 		$div = $(div)
	# 		regex = new RegExp(query, "gi")
	# 		html = $div.html().replace(regex, "<span class=\"highlight-term\">$&</span>")
	# 		$div.html html

	# 	@scrollIntoView @$('span.highlight-term').first()

	# scrollTo: (markerID) ->
	# 	startNode = @annotationStartNode markerID
	# 	scroll = => $('body').scrollTo startNode,
	# 		axis: 'y'
	# 		duration: 500
	# 		offset:
	# 			top: -50
	# 			left: 0
	# 	_.delay scroll, 1000 # wait for render to complete

	scrollIntoView: ($el) ->
		if $el.length > 0 and not dom($el[0]).inViewport()
			supAbsoluteTop = $el.offset().top
			@options.scrollEl.animate
				scrollTop: supAbsoluteTop - 40

	annotationStartNode: (markerID) -> @el.querySelector("span[data-marker=\"begin\"][data-id=\"#{markerID}\"]")
	annotationEndNode: (markerID) -> @el.querySelector("sup[data-marker=\"end\"][data-id=\"#{markerID}\"]")

	highlightOn: (markerId) ->
		startNode = @annotationStartNode(markerId)
		endNode = @annotationEndNode(markerId)

		hl = dom(startNode).highlightUntil(endNode).on()

	highlightOff: (markerId) -> hl.off() if hl?

	startListening: ->
		@listenTo @options.eventBus, 'highlight-annotation', (markerId) =>	@highlightOn markerId 
		@listenTo @options.eventBus, 'unhighlight-annotation', (markerId) => @highlightOff markerId

		@listenTo @options.eventBus, 'send:toggle:annotation', (markerId) =>
			@options.eventBus.trigger 'toggle:annotation', markerId, dom(@$('sup[data-id="'+markerId+'"]')[0]).position(@el).top

module.exports = EntryTextView