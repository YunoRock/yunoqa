
lfs = require "lfs"

tap = require "yunoqa.tap"

TestsResults = require "yunoqa.tests_results"

class
	new: (arg) =>
		-- FIXME: Make that an error.
		@name = arg.name or "(unnamed project)"

		-- FIXME: Compatibility
		@project = @name

		@results = {}
		@environments = {}

	importResults: (configuration) =>
		for entry in lfs.dir "#{configuration.resultsDirectory}/#{@name}"
			if entry == "." or entry == ".."
				continue

			-- Other formats *might* be supported in the future. No promises though.
			if not entry\match "%.tap$"
				continue

			results = TestsResults.from_filename "#{configuration.resultsDirectory}/#{@name}/#{entry}"
			table.insert @results, results

		table.sort @results, (a, b) ->
			a.date > b.date

		@environments = do
			_T = {}

			environments = {}
			for results in *@results
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

	__tostring: =>
		"<yunoqa.Project>"

