Backbone = require 'backbone'
us = require 'underscore.string'

basePath = window.BASE_URL
basePath = '' if basePath is '/'

class Config extends Backbone.Model

	url: -> "#{basePath}/data/config.json"
	
	defaults: ->
		restUrl: 'http://rest.elaborate.huygens.knaw.nl/'
		basePath: basePath
		appRootElement: '#app'
		entryTermSingular: 'entry'
		entryTermPlural: 'entries'
		searchPath: "/api/search"
		resultRows: 25
		annotationsIndexPath: "#{basePath}/data/annotation_index.json"
		roles:
			'READER': 10
			'USER': 20
			'PROJECTLEADER': 30
			'ADMIN': 40

	parse: (data) ->
		for entry in data.entries
			entry._id = +entry.datafile.replace '.json', '' 
			entry.thumbnails = data.thumbnails[entry._id]

		tls = []
		tls.push id: textlayer for textlayer in data.textLayers
		data.textlayers = tls

		data

	slugToLayer: (slug) ->
		for layer in @get('textLayers') || []
			if slug is us.slugify layer
				return layer

module.exports = new Config