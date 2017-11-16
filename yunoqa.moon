#!/usr/bin/env moon

argparse = require "argparse"
lfs = require "lfs"
toml = require "toml"

tap = require "yunoqa.tap"
templates = require "yunoqa.templates"

Configuration = =>
	@unit or= {}

	self

configuration = do
	configFile = io.open "qa.toml", "r"
	content = configFile\read "*all"
	Configuration toml.parse content

for suite in *configuration.unit
	print "project:", suite.project

	resultsList = {}

	for entry in lfs.dir suite.project
		if entry == "." or entry == ".."
			continue
		elseif not entry\match "%.tap$"
			continue

		date, environmentName, revisionName = entry\match "(.*)#(.*)#(.*)%.tap$"
		print "revision: ", suite.project, revisionName

		file = io.open (suite.project .. "/" .. entry), "r"
		content = file\read "*all"

		results = tap.parse content

		results.date = date
		results.revisionName = revisionName
		results.environmentName = environmentName

		table.insert resultsList, results

		--require("pl.pretty").dump results
		outputFileName = "output/#{suite.project}-#{environmentName}-#{revisionName}.xhtml"
		print (outputFileName\gsub "%s", "%%20")

		outputFile = io.open outputFileName, "w"
		outputFile\write templates.singleResultsPage results, suite
		outputFile\close!

	table.sort resultsList, (a, b) ->
		a.date > b.date

	for results in *resultsList
		table.insert suite, results

	suite.resultsPerEnvironment = do
		_T = {}
		environments = {}
		for results in *suite
			{:environmentName} = results

			environments[environmentName] or= {
				name: environmentName
			}

			table.insert environments[environmentName], results

		for name, environment in pairs environments
			_T[#_T+1] = environment
			table.sort _T[#_T], (a, b) -> a.date > b.date

		table.sort _T, (a, b) -> a.name < b.name

		_T

	outputFileName = "output/#{suite.project}.xhtml"
	print (outputFileName\gsub "%s", "%%20")

	outputFile = io.open outputFileName, "w"
	outputFile\write templates.projectResultsPage suite
	outputFile\close!

outputFileName = "output/index.xhtml"
print (outputFileName\gsub "%s", "%%20")

outputFile = io.open outputFileName, "w"
outputFile\write templates.indexPage configuration
outputFile\close!


