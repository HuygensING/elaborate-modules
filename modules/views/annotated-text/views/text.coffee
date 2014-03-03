Backbone = require 'backbone'
$ = require 'jquery'
_ = require 'underscore'

dom = require 'hilib/src/utils/dom'
require 'hilib/src/utils/jquery.mixin'

events = require '../events'

tpl = require '../templates/text.jade'

config = require '../../../models/config'

range = null

class EntryTextView extends Backbone.View

	className: 'text'

	# ### Initialize

	initialize: (@options) ->
		@highlighter = rangy.createCssClassApplier 'highlight'
		@render()

	# ### Render

	render: ->
		text = @options.paralleltexts[@options.textlayers.current.id].text

		# Doing this to ensure empty lines get correct height, so as not to mess with line numbering
		if text?
			text = String(text).replace /<div class="line">\s*<\/div>/mg, '<div class="line">&nbsp;</div>'

		@$el.html tpl textlayers: @options.textlayers
		@$el.fadeOut(75).append(text).fadeIn(75)

		enter = (ev) => 
			markerId = ev.currentTarget.getAttribute 'data-id'
			events.trigger 'activate:annotation', markerId
			@highlightOn markerId
		leave = (ev) => 
			markerId = ev.currentTarget.getAttribute 'data-id'
			events.trigger 'unactivate:annotation', markerId
			@highlightOff markerId
		@$('sup[data-marker]').hover enter, leave

		@$el.addClass config.get('textFont')

		@

	# ### Events
	events:
		'change header select': 'changeTextlayer'
		'click i.btn-print': (e) -> window.print()
		'click sup[data-marker]': 'toggleAnnotation'

	toggleAnnotation: (ev) ->
		markerId = ev.currentTarget.getAttribute 'data-id'
		supTop = dom(ev.currentTarget).position(@el).top
		
		events.trigger 'toggle:annotation', markerId, supTop

	changeTextlayer: (ev) -> 
		ev = ev.currentTarget.options[ev.currentTarget.selectedIndex].value if ev.hasOwnProperty 'currentTarget'
		@options.textlayers.setCurrent ev

	# ### Methods

	highlightAnnotation: (markerId) ->
		@highlightOn markerId

		$sup = @$ "sup[data-id='#{markerId}']"
		# console.log markerId, $sup, dom($sup[0]).position(), dom($sup[0]).position(@el).top

		events.trigger 'toggle:annotation', markerId, dom($sup[0]).position(@el).top

		@scrollIntoView $sup

	markTerm: (query) ->
		$divs = @$("div.line:contains('#{query}')")
		_.each $divs, (div) ->
			$div = $(div)
			regex = new RegExp(query, "gi")
			html = $div.html().replace(regex, "<span class=\"highlight-term\">$&</span>")
			$div.html html

		@scrollIntoView @$('span.highlight-term').first()

	scrollTo: (markerID) ->
		startNode = @annotationStartNode markerID
		scroll = => $('body').scrollTo startNode,
			axis: 'y'
			duration: 500
			offset:
				top: -50
				left: 0
		_.delay scroll, 1000 # wait for render to complete

	scrollIntoView: ($el) ->
		if $el.length > 0 and not dom($el[0]).inViewport()
			supAbsoluteTop = $el.offset().top
			$('body, html').animate
				scrollTop: supAbsoluteTop - 40


	annotationStartNode: (markerID) -> @$("span[data-marker=begin][data-id=#{markerID}]")[0]
	annotationEndNode: (markerID) -> @$("sup[data-marker=end][data-id=#{markerID}]")[0]

	highlightOn: (markerId) ->
		range = rangy.createRange()
		range.setStartAfter @annotationStartNode(markerId) 
		range.setEndBefore @annotationEndNode(markerId)

		@highlighter.applyToRange range

	highlightOff: (markerId) ->
		@highlighter.undoToRange range if range? and range.isValid()

	startListening: ->
		@listenTo @options.textlayers, 'change:current', (textlayer) => @render()

		@listenTo events, 'highlight-annotation', (markerId) => @highlightOn markerId 
		@listenTo events, 'unhighlight-annotation', (markerId) => @highlightOff markerId

		@listenTo events, 'send:toggle:annotation', (markerId) =>
			console.log @el
			events.trigger 'toggle:annotation', markerId, dom(@$('sup[data-id="'+markerId+'"]')[0]).position(@el).top

module.exports = EntryTextView