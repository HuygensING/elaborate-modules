Backbone = require 'backbone'

Views =
	Text: require './views/text'
	Annotations: require './views/annotations'

# REQUIRED
# @options.paralleltexts (Object)
# 	An object with textlayer titles as property names. The values consist of an object with a text and
# 	annotationData property. The text property is a String and the annotationData an array of objects.
# @options.annotationTypes (Object)
# 	An object with textlayer titles as property names. The values are objects with key-value pairs of
# 	annotation type titles and the count of occurence.
# @options.textlayers (Backbone.Collection)
# @options.autoListening (Boolean)
# 	When switching views you sometimes want to control the views listening, with the methods startListening
# 	and stopListening you can. When setting autoListening to false, you'll manually have to call those methods.
# 	When set to true (default) startListening will be called on render and stopListening will never be called. You can do that
# 	manually if needed.
#
# OPTIONAL
# @options.annotation (String)
# 	When given, the annotation will be highlighted.
# @options.term (String)
# 	When given, the term(s) will be highlighted in the text.
class AnnotatedText extends Backbone.View

	className: 'elaborate-annotated-text'

	initialize: -> @render()

	render: ->
		@options.autoListening ?= true

		# Get the data for the current text layer. The data is an object with
		# a text and an annotationData property.
		# layerData = @options.paralleltexts[@options.textlayers.current.id]

		# console.log layerData, @options.paralleltexts, @options.textlayers

		@textView = new Views.Text
			paralleltexts: @options.paralleltexts
			textlayers: @options.textlayers
		@$el.html @textView.$el
		
		@annotationsView = new Views.Annotations
			paralleltexts: @options.paralleltexts
			annotationTypes: @options.annotationTypes
			textlayers: @options.textlayers
			$sups: @$('.text sup')
		@$el.append @annotationsView.$el

		@startListening() if @options.autoListening

		setTimeout (=>
			@textView.highlightAnnotation @options.annotation if @options.annotation?
			@textView.markTerm @options.term if @options.term?
		), 1000

	# ### Methods

	startListening: ->
		@textView.startListening()
		@annotationsView.startListening()

	stopListening: ->
		@textView.stopListening()
		@annotationsView.stopListening()

	highlightOff: -> @textView.highlightOff()

module.exports = AnnotatedText