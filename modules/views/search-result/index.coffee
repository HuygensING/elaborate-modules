$ = require 'jquery'
dom = require 'hilib/src/utils/dom'

config = require '../../models/config'

Views =
	Base: require 'hilib/src/views/base'
	EntryListItem: require './views/entry-list-item'
	SortLevels: require '../sort-levels'
	Pagination: require 'hilib/src/views/pagination/main'

tpl = require './templates/main.jade'

class SearchResult extends Views.Base

	className: 'results-placeholder'

	initialize: -> 
		super

		@render()

	render: ->
		@$el.html tpl()

		@renderHeader()

		queryOptions = @options.responseModel.options?.queryOptions ? {}
		fulltext = queryOptions.term? and queryOptions.term isnt ''

		# Create a document fragment and append entry listitem views.
		frag = document.createDocumentFragment()
		for result in @options.responseModel.get 'results'
			# TODO: destroy listitems on @destroy()
			entryListItem = new Views.EntryListItem
				entryData: result
				fulltext: fulltext
			@listenTo entryListItem, 'click', (id, terms, textLayer) -> @trigger 'navigate:entry', id, terms, textLayer
			frag.appendChild entryListItem.el

		# Add the frag to the dom
		ulentries = @$('ul.entries')
		ulentries.html frag
	
		# Wait for DOM to update	
		# setTimeout (-> ulentries.height $(window).height() - ulentries.offset().top), 0

		@

	renderHeader: ->
		@el.querySelector('h3.numfound').innerHTML = @options.responseModel.get('numFound') + " #{config.get('entryTermPlural')} found"

		@renderLevels()
		@renderPagination()

	renderLevels: ->
		if @subviews.sortLevels?
			@stopListening @subviews.sortLevels
			@subviews.sortLevels.destroy()

		@subviews.sortLevels = new Views.SortLevels
			levels: @options.levels
			entryMetadataFields: @options.entryMetadataFields
		@$('header li.levels').html @subviews.sortLevels.$el
		
		@listenTo @subviews.sortLevels, 'change', (sortParameters) => @trigger 'change:sort-levels', sortParameters

	renderPagination: ->
		if @subviews.pagination?
			@stopListening @subviews.pagination
			@subviews.pagination.destroy()

		@subviews.pagination = new Views.Pagination
			start: @options.responseModel.get('start')
			rowCount: @options.resultRows
			resultCount: @options.responseModel.get('numFound')
		@listenTo @subviews.pagination, 'change:pagenumber', (pagenumber) => @trigger 'change:pagination', pagenumber
		@$('header .pagination').html @subviews.pagination.el

	events: ->
		'change li.show-metadata input': 'showMetadata'

	showMetadata: (ev) -> @$('.metadata').toggle ev.currentTarget.checked

module.exports = SearchResult