Backbone = require 'backbone'
us = require 'underscore.string'

basePath = window.BASE_URL
basePath = '' if basePath is '/'

# URL is passed in through app init
class Config extends Backbone.Model

	url: -> "#{basePath}/data/config.json"
	
	defaults: ->
		baseUrl: 'http://rest.elaborate.huygens.knaw.nl/'
		basePath: basePath
		appRootElement: '#app'
		entryTermSingular: 'entry'
		entryTermPlural: 'entries'
		searchPath: "#{basePath}/api/search"
		# searchPath: 'http://demo7.huygens.knaw.nl/elab4-gemeentearchief_kampen/api/search'
		resultRows: 25
		annotationsIndexPath: "#{basePath}/data/annotation_index.json"
		roles:
			'READER': 10
			'USER': 20
			'PROJECTLEADER': 30
			'ADMIN': 40

	initialize: ->

	parse: (data) ->
		for entry in data.entries
			entry._id = +entry.datafile.replace '.json', '' 
			entry.thumbnails = data.thumbnails[entry._id]

		tls = []
		tls.push id: textlayer for textlayer in data.textLayers
		data.textlayers = tls

		data

	# entries: ->
	# 	entry.datafile.replace '.json', '' for entry in @get 'entries'

	# annotationsIndexURL: ->
	# 	basePath + '/data/' + @get('annotationIndex')

	# entryMarkTermURL: (id, layer, term) -> "entry/#{id}/#{us.slugify layer}/mark/#{term}"

	# searchURL: -> basePath+"/api/search"

	slugToLayer: (slug) ->
		for layer in @get('textLayers') || []
			if slug is us.slugify layer
				return layer

module.exports = new Config