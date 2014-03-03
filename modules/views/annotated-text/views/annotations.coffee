Backbone = require 'backbone'
$ = require 'jquery'
_ = require 'underscore'

dom = require 'hilib/src/utils/dom'

events = require '../events'

Annotations = require '../collections/annotations'

tpl = require '../templates/annotations.jade'

class AnnotationsView extends Backbone.View

	className: 'annotations'

	# ### Initialize

	initialize: ->
		@expandAnnotations = false

		@render()

		# @startListening()

	# ### Render
	# Render is called from the textView, because the annotationsView needs a list of the
	# sups that are rendered in the textView.
	render: ->
		annotationData = @options.paralleltexts[@options.textlayers.current.id].annotationData

		# annotations = layerData.annotationData
		annotationTypes = @options.annotationTypes[@options.textlayers.current.id]

		annotations = {}
		annotations[annotation.n] = annotation for annotation in annotationData ? []

		orderedAnnotations = new Annotations()
		orderedAnnotations.add annotations[id] for id in (@options.$sups.map (index, sup) -> sup.getAttribute('data-id'))

		@$el.html tpl
			annotations: orderedAnnotations
			annotationTypes: annotationTypes

		@toggleAnnotations true if @expandAnnotations

		enter = (ev) => events.trigger 'highlight-annotation', ev.currentTarget.getAttribute 'data-id'
		leave = (ev) => events.trigger 'unhighlight-annotation', ev.currentTarget.getAttribute 'data-id'
		@$('ol li').hover enter, leave

		@

	# ### Events
	events:
		'click i.btn-collapse': 'toggleAnnotations'
		'change header select': 'filterAnnotations'
		'click li': 'sendToggleAnnotation'

	# The 'send-toggle-annotation' event tells the textView it should send the toggle:annotation event.
	# We do this, because we need the supTop (the top position of the <sup> with data-id=markerId in the textView)
	# when aligning the sup[data-id] with li[data-id].
	sendToggleAnnotation: (ev) -> events.trigger 'send:toggle:annotation', ev.currentTarget.getAttribute 'data-id'

	filterAnnotations: (ev) ->
		type = ev.currentTarget[ev.currentTarget.selectedIndex].value

		if type is 'show-all-annotations'
			@$('ol li').removeClass 'hide'
		else
			@$('ol li:not([data-type="'+type+'"])').addClass 'hide'
			@$('ol li[data-type="'+type+'"]').removeClass 'hide'

		@resetAnnotations()

	toggleAnnotations: (flag) ->
		$target = @$ 'i.btn-collapse'

		@expandAnnotations = if _.isBoolean flag then flag else $target.hasClass 'fa-expand' 

		# If we expand the annotations, the button should change to 'compress' and vice versa.
		if @expandAnnotations
			$target.addClass 'fa-compress'
			$target.removeClass 'fa-expand'
		else
			$target.removeClass 'fa-compress'
			$target.addClass 'fa-expand'

		@$('ol').toggleClass('active', @expandAnnotations)

		@resetAnnotations()

	# ### Methods

	resetAnnotations: ->
		@$('ol li.show').removeClass 'show'

		# Reset the top position of the <ol>, because it could be moved by the user.
		@$('ol').animate top: 0

	toggleAnnotation: (ev) ->
		$target = if ev.hasOwnProperty 'currentTarget' then @$ ev.currentTarget else @$ 'li[data-id="'+ev+'"]'
		$target.toggleClass('show').siblings().removeClass 'show'

	slideAnnotations: (markerId, supTop) ->
		$li = @$('li[data-id="'+markerId+'"]')

		# To align an annotation in the list with the corresponding marker,
		# we set the top position of the list (<ol>) to the position of the marker
		# minus the position of the annotation (<li>) within the list and
		# subtract the height of the header (40px) and add some text offset (4px).
		top = supTop - $li.position().top - 36

		# Scroll the list to it's new top position.
		@$('ol').animate top: top, 400, =>
			# Scroll the annotation into view if it is not visible for the user.
			unless dom($li[0]).inViewport()
				liAbsoluteTop = $li.offset().top
				# Firefox sets overflow to html (instead of body) so we call body ánd html.
				$('body,html').animate scrollTop: liAbsoluteTop - 20

	startListening: ->
		@listenTo @options.textlayers, 'change:current', (textlayer) => @render()

		@listenTo events, 'toggle:annotation', (markerId, supTop) =>
			@toggleAnnotation markerId
			@slideAnnotations markerId, supTop

		@listenTo events, 'activate:annotation', (markerId) => @$('li[data-id="'+markerId+'"]').addClass 'active'
		@listenTo events, 'unactivate:annotation', (markerId) => @$('li[data-id="'+markerId+'"]').removeClass 'active'

module.exports = AnnotationsView