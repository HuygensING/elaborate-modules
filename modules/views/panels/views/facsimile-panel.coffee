Backbone = require 'backbone'

tpl = require '../templates/facsimile-panel.jade'

class FacsimilePanel extends Backbone.View

	className: 'facsimile'

	# ### Initialize
	initialize: -> @render()

	# ### Render
	render: ->
		@$el.html tpl
			entry: @options.entry
			zoomUrl: @options.zoomUrl

		@

	destroy: -> @remove()

module.exports = FacsimilePanel