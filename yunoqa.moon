#!/usr/bin/env moon

argparse = require "argparse"
lfs = require "lfs"
toml = require "toml"

tap = require "yunoqa.tap"
templates = require "yunoqa.templates"
{:mkdir_p} = require "yunoqa.utils"

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

cliParser = with argparse arg[0], "Test results aggregator."
	\command "show"

	with \command "html", "Generates a set of HTML pages."
		\option "-o --output", "Output directory", "output/"

	with \command "add", "Registers a new set of test results to a given project."
		\argument "project", "Name of the project whose tests were run."
		\argument "environment", "Name of the environment in which the tests were run."
		\argument "revision", "Revision of the project whose tests were run."

args = cliParser\parse!

if args.add
	local project

	for p in *configuration.projects
		if p.name == args.project
			project = p
			break

	unless project
		io.stderr\write "No such project exists in the configuration!\n"
		os.exit 1


	print args.project, args.environment, args.revision

	directoryName = "#{configuration.resultsDirectory}/#{project.name}"
	mkdir_p directoryName

	file = io.open "#{directoryName}/#{project.name}##{args.environment}##{args.revision}.tap", "w"
	for line in io.stdin\lines!
		file\write line
	file\close!
elseif args.show
	for project in *configuration.projects
		print "project:", project.name
		for results in *project.results
			print "results:", results.revisionName
elseif args.html
	outputDirectory = args.output

	mkdir_p outputDirectory

	-- FIXME: Alternate output (ie. plain text, vt100, etc.).
	for project in *configuration.projects
		print "project:", project.name

		resultsList = project.results

		for results in *project.results
			print "results:", results.revisionName

			outputFileName = "#{outputDirectory}/#{project.name}-#{results.date\gsub ":", "-"}-#{results.environmentName}-#{results.revisionName}.xhtml"
			print "output: ", (outputFileName\gsub "%s", "%%20")

			outputFile, reason = io.open outputFileName, "w"
			unless outputFile
				io.stderr\write "#{reason}\n"
				continue
			outputFile\write templates.singleResultsPage results, project
			outputFile\close!

		outputFileName = "#{outputDirectory}/#{project.name}.xhtml"
		print "output: ", (outputFileName\gsub "%s", "%%20")

		outputFile = io.open outputFileName, "w"
		outputFile\write templates.projectResultsPage project
		outputFile\close!

	outputFileName = "#{outputDirectory}/index.xhtml"
	print "output: ", (outputFileName\gsub "%s", "%%20")

	outputFile = io.open outputFileName, "w"
	outputFile\write templates.indexPage configuration
	outputFile\close!

