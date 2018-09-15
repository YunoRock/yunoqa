
lfs = require "lfs"
moonscript = require "moonscript"

tap = require "yunoqa.tap"

TestsResults = require "yunoqa.tests_results"

class
	new: (name, arg) =>
		@name = name

		-- FIXME: Compatibility
		@project = @name

		@results = {}
		@environments = {}

		@template = do
			template = arg.template

			switch type template
				when "string"
					moonscript.loadfile(template)!
				when "function"
					template

	importResults: (configuration) =>
		resultsDirectory = "#{configuration.resultsDirectory}/#{@name}"
		unless lfs.attributes resultsDirectory
			-- FIXME: We should probably check it’s a directory too.
			return nil, "results directory does not exist"

		for entry in lfs.dir resultsDirectory
			if entry == "." or entry == ".."
				continue

			-- Other formats *might* be supported in the future. No promises though.
			if not entry\match "%.tap$"
				continue

			success, results = pcall ->
				TestsResults.from_filename "#{configuration.resultsDirectory}/#{@name}/#{entry}"

			unless success
				io.stderr\write "!! loading '#{@name}/#{entry}' failed\n"
				io.stderr\write "!! ... reason: #{results}\n"
				continue

			table.insert @results, results

		table.sort @results, (a, b) ->
			aDate = [tonumber m for m in a.date\gmatch "[0-9]+"]
			bDate = [tonumber m for m in b.date\gmatch "[0-9]+"]
	
			for i = 1, #aDate
				if aDate[i] > bDate[i]
					return true
				elseif aDate[i] < bDate[i]
					return false

			false

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
		"<yunoqa.Project: '#{@name}'>"

