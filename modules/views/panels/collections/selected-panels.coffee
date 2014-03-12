Backbone = require 'backbone'

textlayers = require 'elaborate-modules/modules/collections/textlayers'

class SelectedPanel extends Backbone.Model
	
	defaults: ->
		type: ''

class SelectedPanels extends Backbone.Collection
	
	model: SelectedPanel

	comparator: 'type'
	# initialize: (models, options) ->

module.exports = SelectedPanels