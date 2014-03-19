Backbone = require 'backbone'
_ = require 'underscore'
us = require 'underscore.string'
$ = require 'jquery'

dom = require 'hilib/src/utils/dom'

config = require '../../models/config'

textlayers = require '../../collections/textlayers'
entries = require '../../collections/entries'

Views =
	AnnotatedText: require '../annotated-text/annotated-text'
	PanelsMenu: require './views/panels-menu'
	FacsimilePanel: require './views/facsimile-panel'

tpl = require './templates/main.jade'

KEYCODE_ESCAPE = 27

class Panels extends Backbone.View

	tagName: 'article'

	# ### Initialize
	initialize: (@options={}) ->
		super

		@subviews = []

		modelLoaded = =>		
			entries.setCurrent @model.id
			@el.setAttribute 'id', 'entry-'+@model.id
			@render()

		# The IDs of the entries are passed to the collection on startup, so we can not check
		# isNew() if we need to fetch the full model or it already has been fetched.
		if @model = entries.get @options.entryId
			modelLoaded()
		else
			@model = if @options.entryId? then entries.findWhere datafile: @options.entryId+'.json' else entries.current

			@model.fetch().done => modelLoaded()

		$(window).resize @setHeights

	# ### Render
	render: ->
		rtpl = tpl
			metadata: @model.get('metadata') || []
			entryName: @model.get('name')
		@$el.html rtpl

		# @renderMetadata()
		@renderPanelsMenu()
		@renderPanels()

		@startListening()

		setTimeout @postRender.bind(@), 500

		@

	setHeights: ->
		panels = $('article .panels')
		panels.height $(window).height() - panels.offset().top

		metadataList = $('article .metadata ul')
		metadataList.css 'max-height', $(window).height() - metadataList.offset().top

	postRender: ->
		@setHeights()

		if @options.layerSlug?
			activePanel = config.get('selectedPanels').get us.capitalize @options.layerSlug
			return unless activePanel?
			
			activePanelLeft = activePanel.get('view').$el.position().left
			activePanelWidth = activePanel.get('view').$el.width()
			windowWidth = $(window).width()

			hasScrollbar = @$('.panels')[0].scrollWidth > windowWidth
			panelOutOfView = @$('.panels')[0].scrollLeft + windowWidth < activePanelLeft + activePanelWidth

			if hasScrollbar and panelOutOfView
				@$('.panels').animate scrollLeft: activePanelLeft, 400, =>
					if @options.annotation?
						activePanel.get('view').highlightAnnotation @options.annotation
			else if @options.annotation?
				activePanel.get('view').highlightAnnotation @options.annotation

			if @options.terms?
				# console.log @options.highlightAnnotations, @options
				if @options.highlightAnnotations
					activePanel.get('view').highlightTermsInAnnotations Object.keys(@options.terms)
				else
					activePanel.get('view').highlightTerms Object.keys(@options.terms)

	renderPanelsMenu: ->
		@options.facsimiles = @model.get('facsimiles')
		panelsMenu = new Views.PanelsMenu @options
		@$el.prepend panelsMenu.$el

		@subviews.push panelsMenu

	renderPanels: ->
		@$('.panels').html ''
		@renderPanel panel for panel in config.get('selectedPanels').models

	renderPanel: (panel) ->
		if panel.get('type') is 'facsimile'
			view = @renderFacscimile panel.id
		else
			view = @renderTextLayer panel.id

		panel.set 'view', view

		@$('.panels').append view.$el
		
		dom(panel.get('view').el).toggle 'inline-block', panel.get('show')


	renderFacscimile: (zoomUrl) ->
		facsimilePanel = new Views.FacsimilePanel
			entry: @model.attributes
			zoomUrl: zoomUrl

		@subviews.push facsimilePanel

		facsimilePanel

	renderTextLayer: (textLayer) ->
		options =
			paralleltexts: @model.get('paralleltexts')
			annotationTypes: @model.get('annotationTypes')
			textLayer: textLayer
			scrollEl: @$('.panels')

		options.annotation = @options.annotation if @options.annotation?
		options.term = @options.mark if @options.mark?

		@annotatedText = new Views.AnnotatedText options

		@subviews.push @annotatedText

		@annotatedText

	# ### Events
	events:
		# 'click button.toggle-metadata': -> @$('.metadata').toggleClass 'show-all'
		'click button.toggle-metadata': -> @$('.metadata ul').slideToggle('fast')
		'click i.print': -> window.print()

	# ### Methods
	destroy: ->
		view.destroy() for view in @subviews
		@remove()

	startListening: ->
		@listenTo config.get('selectedPanels'), 'change:show', (panel, value, options) =>
			$el = panel.get('view').$el
			$el.toggle value
			if value
				@$('.panels').animate scrollLeft: $el.position().left
		@listenTo config.get('selectedPanels'), 'sort', @renderPanels
	
module.exports = Panels