Backbone = require 'backbone'
$ = require 'jquery'

dom = require 'hilib/src/utils/dom'

Views =
	Base: require 'hilib/src/views/base'

tpl = require './templates/main.jade'

# @options
# 	project	Backbone.Model The current project

class SortLevels extends Views.Base

	tagName: 'li'

	className: 'sort-levels'

	# ### Initialize
	initialize: (@options={}) ->
		@render()

	# ### Render
	render: ->
		rtpl = tpl
			levels: @options.levels
			entryMetadataFields: @options.entryMetadataFields
		@$el.html rtpl

		@listenTo Backbone, 'sortlevels:update', (sortLevels) =>
			@options.levels = sortLevels

			sortParameters = []
			sortParameters.push fieldname: level, direction: 'asc' for level in sortLevels
			@trigger 'change', sortParameters

			@render()

		@listenTo Backbone, 'entrymetadatafields:update', (fields) =>
			@options.entryMetadataFields = fields
			@render()

		# TODO turn off on destroy
		levels = @$('div.levels')
		levels.mouseleave (ev) =>
			# The leave event is triggered when the user clicks the <select>,
			# so we check if the target isn't part of div.levels
			levels.hide() unless dom(levels[0]).hasDescendant(ev.target) or levels[0] is ev.target

	# ### Events
	events: ->
		'click button.toggle': 'toggleLevels'
		'click li.search button': 'saveLevels'
		'change div.levels select': 'changeLevels'
		'click div.levels i.fa': 'changeAlphaSort'

	toggleLevels: (ev) ->
		@$('div.levels').toggle()

	hideLevels: ->
		@$('div.levels').hide()

	changeLevels: (ev) ->
		@$('div.levels').addClass 'show-save-button'

		target = ev.currentTarget

		# Loop the selects.
		for select in @el.querySelectorAll 'div.levels select'
			# Set a select to empty if it has the same value as the user has selected.
			select.selectedIndex = 0 if select.name isnt target.name and select.value is target.value

		# Reset all selects to ascending.
		for i in @el.querySelectorAll 'div.levels i.fa'
			$target = @$(i)
			$target.addClass 'fa-sort-alpha-asc'
			$target.removeClass 'fa-sort-alpha-desc'

	changeAlphaSort: (ev) ->
		@$('div.levels').addClass 'show-save-button'

		$target = @$(ev.currentTarget)
		$target.toggleClass 'fa-sort-alpha-asc'
		$target.toggleClass 'fa-sort-alpha-desc'

	saveLevels: ->
		sortParameters = []

		for li in @el.querySelectorAll 'div.levels li[name]'
			select = li.querySelector('select')

			sortParameter = {}
			sortParameter.fieldname = select.options[select.selectedIndex].value
			sortParameter.direction = if $(li).find('i.fa').hasClass 'fa-sort-alpha-asc' then 'asc' else 'desc'

			sortParameters.push sortParameter

		@hideLevels()

		@trigger 'change', sortParameters

module.exports = SortLevels