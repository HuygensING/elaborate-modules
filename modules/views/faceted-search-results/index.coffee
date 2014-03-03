$ = require 'jquery'

Fn = require 'hilib/src/utils/general'
dom = require 'hilib/src/utils/dom'
token = require 'hilib/src/managers/token'


config = require '../../models/config'

Entry = require '../../models/entry'

Views =
	Base: require 'hilib/src/views/base'
	FacetedSearch: require 'faceted-search'
	EditMultipleMetadata: require './views/edit-multiple-metadata'
	SearchResult: require '../search-result'

tpl = require './templates/main.jade'

class FacetedSearchResults extends Views.Base

	className: 'faceted-search-results'

	# ### Initialize
	initialize: ->
		super

		@resultRows = 50

		# @options.projects.getCurrent (@project) => @render()
		@render()

	# ### Render
	render: ->
		rtpl = tpl
			entryTermSingular: config.get('entryTermSingular')
		@$el.html rtpl

		@renderFacetedSearch()

		@

	renderFacetedSearch: ->
		# @subviews.facetedSearch = new Views.FacetedSearch
		@subviews.facetedSearch = new Views.FacetedSearch
			# baseUrl: config.get('baseUrl')
			# searchPath: 'projects/'+@project.id+'/search'
			searchPath: @options.searchUrl
			token: token.get()
			textSearchOptions:
				textLayers: @options.textLayers
				searchInAnnotations: true
				searchInTranscriptions: true
			queryOptions:
				resultRows: @resultRows
				resultFields: @options.levels
		@$('.faceted-search-placeholder').html @subviews.facetedSearch.el

		@listenTo @subviews.facetedSearch, 'unauthorized', => Backbone.history.navigate 'login', trigger: true

		@listenTo @subviews.facetedSearch, 'results:change', (responseModel) =>
			@trigger 'change:results', responseModel
			# @project.resultSet = responseModel
			# @renderHeader responseModel
			@renderResult responseModel

	# renderHeader: (responseModel) ->
	# 	@el.querySelector('h3.numfound').innerHTML = responseModel.get('numFound') + " #{config.get('entryTermPlural')} found"

	# 	@renderLevels()

	# 	if @subviews.pagination?
	# 		@stopListening @subviews.pagination
	# 		@subviews.pagination.destroy()

	# 	@subviews.pagination = new Views.Pagination
	# 		start: responseModel.get('start')
	# 		rowCount: @resultRows
	# 		resultCount: responseModel.get('numFound')
	# 	@listenTo @subviews.pagination, 'change:pagenumber', (pagenumber) => @subviews.facetedSearch.page pagenumber
	# 	@$('.pagination').html @subviews.pagination.el

	# renderLevels: ->
	# 	@subviews.sortLevels = new Views.SortLevels
	# 		levels: @options.levels
	# 		entryMetadataFields: @options.entryMetadataFields
	# 	@$('header li.levels').html @subviews.sortLevels.$el
		
	# 	@listenTo @subviews.sortLevels, 'change', (sortParameters) => 
	# 		@subviews.facetedSearch.refresh sortParameters: sortParameters

	renderResult: (responseModel) ->
		@subviews.searchResult = new Views.SearchResult
			responseModel: responseModel
			levels: @options.levels
			entryMetadataFields: @options.entryMetadataFields
			resultRows: @resultRows
		@$('.resultview').html @subviews.searchResult.$el

		@listenTo @subviews.searchResult, 'change:sort-levels', (sortParameters) => @subviews.facetedSearch.refresh sortParameters: sortParameters
		@listenTo @subviews.searchResult, 'change:pagination', (pagenumber) => @subviews.facetedSearch.page pagenumber
		@listenTo @subviews.searchResult, 'navigate:entry', (id, terms) => @trigger 'navigate:entry', id, terms

	# ### Events
	events:
		'change li.select-all input': (ev) -> Fn.checkCheckboxes '.entries input[type="checkbox"]', ev.currentTarget.checked, @el
		'change li.display-keywords input': (ev) -> if ev.currentTarget.checked then @$('.keywords').show() else @$('.keywords').hide()
		# TODO: Move change event to entry-list-item.coffee
		'change .entry input[type="checkbox"]': -> @subviews.editMultipleEntryMetadata.activateSaveButton()

	changePage: (ev) ->
		cl = ev.currentTarget.classList
		return if cl.contains 'inactive'

		@el.querySelector('li.prev').classList.remove 'inactive'
		@el.querySelector('li.next').classList.remove 'inactive'

		if cl.contains 'prev'
			@subviews.facetedSearch.prev()
		else if cl.contains 'next'
			@subviews.facetedSearch.next()


	# navToEntry: (ev) ->
	# 	# If edit multiple metadata is active, we don't navigate to the entry when it is clicked,
	# 	# instead a click toggles a checkbox which is used by edit multiple metadata.
	# 	placeholder = @el.querySelector('.editselection-placeholder')
	# 	return if placeholder? and placeholder.style.display is 'block'

	# 	entryID = ev.currentTarget.getAttribute 'data-id'
	# 	Backbone.history.navigate "projects/#{@project.get('name')}/entries/#{entryID}", trigger: true

	# ### Methods

	uncheckCheckboxes: -> Fn.checkCheckboxes '.entries input[type="checkbox"]', false, @el

	reset: -> @subviews.facetedSearch.reset()
	refresh: (queryOptions) -> @subviews.facetedSearch.refresh(queryOptions)

	toggleEditMultipleMetadata: ->
		# ul.entries is used twice so we define it on top.
		entries = $('ul.entries')

		@$('.resultview').toggleClass 'edit-multiple-entry-metadata'

		# Class has been added, so we add the form
		if @$('.resultview').hasClass 'edit-multiple-entry-metadata'				
			# Create the form.
			@subviews.editMultipleEntryMetadata = new Views.EditMultipleMetadata
				entryMetadataFields: @options.entryMetadataFields
				editMultipleMetadataUrl: @options.editMultipleMetadataUrl
			@$('.editselection-placeholder').html @subviews.editMultipleEntryMetadata.el
			
			# Add listeners.
			@listenToOnce @subviews.editMultipleEntryMetadata, 'close', => @toggleEditMultipleMetadata()
			@listenToOnce @subviews.editMultipleEntryMetadata, 'saved', (entryIds) => 
				@subviews.facetedSearch.refresh()
				@trigger 'editmultipleentrymetadata:saved', entryIds
		# Class has been removed, so we remove the form
		else
			# Uncheck all checkboxes in the result list.
			Fn.checkCheckboxes null, false, entries[0]

			# Remove the form.
			@stopListening @subviews.editMultipleEntryMetadata
			@subviews.editMultipleEntryMetadata.destroy()

		# Resize result list, because result list height is dynamically calculated on render and the appearance
		# and removal of the edit multiple metadata form alters the top position of the result list.
		entries.height $(window).height() - entries.offset().top

module.exports = FacetedSearchResults