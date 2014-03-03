_ = require 'underscore'

Fn = require 'hilib/src/utils/general'

Base = require 'hilib/src/views/base'

# Tpl = require 'text!html/entry/metadata.html'
tpl = require '../templates/entry-list-item.jade'

# @options
# 	fulltext	Boolean		Is the list a result of a fulltext search? Defaults to false.

# ## EntryMetadata
class EntryListItem extends Base

	className: 'entry'

	tagName: 'li'

	# ### Initialize
	initialize: ->
		super

		@options.fulltext ?= false

		@render()

	# ### Render
	render: ->
		found = []
		found.push "#{count}x #{term}" for own term, count of @options.entryData.terms

		data = _.extend @options,
			entryData: @options.entryData
			generateID: Fn.generateID
			found: found.join(', ')

		rtpl = tpl data
		@$el.html rtpl

		@

	# ### Events
	events: ->
		'click': (ev) ->
			if @$('.default-mode').is(":visible")
				@trigger 'click', @options.entryData.id, @options.entryData.terms
			else if @$('.edit-mode').is(":visible")
				@$('input')[0].checked = !@$('input')[0].checked

module.exports = EntryListItem