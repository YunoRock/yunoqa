#!/usr/bin/env moon

argparse = require "argparse"
lfs = require "lfs"
toml = require "toml"

tap = require "yunoqa.tap"
templates = require "yunoqa.templates"

TestResults = require "yunoqa.tests_results"
Project = require "yunoqa.project"

Configuration = class
	---
	-- Designed to take a parsed TOML file as input.
	new: (arg) =>
		@resultsDirectory = arg["results-directory"] or "."

		@projects = [Project project for project in *(arg.project or {})]

	importResults: =>
		for project in *@projects
			project\importResults self

	__tostring: =>
		"<yunoqa.Configuration>"

configuration = do
	configFile = io.open "qa.toml", "r"
	content = configFile\read "*all"
	with Configuration toml.parse content
		\importResults!

-- FIXME: Alternate output (ie. plain text, vt100, etc.).
for project in *configuration.projects
	print "project:", project.name

	resultsList = project.results

	for results in *project.results
		print "results:", results.revisionName

		--require("pl.pretty").dump results
		outputFileName = "output/#{project.name}-#{results.environmentName}-#{results.revisionName}.xhtml"
		print "output: ", (outputFileName\gsub "%s", "%%20")

		outputFile = io.open outputFileName, "w"
		outputFile\write templates.singleResultsPage results, project
		outputFile\close!

	outputFileName = "output/#{project.name}.xhtml"
	print "output: ", (outputFileName\gsub "%s", "%%20")

	outputFile = io.open outputFileName, "w"
	outputFile\write templates.projectResultsPage project
	outputFile\close!

outputFileName = "output/index.xhtml"
print "output: ", (outputFileName\gsub "%s", "%%20")

outputFile = io.open outputFileName, "w"
outputFile\write templates.indexPage configuration
outputFile\close!


