#!/usr/bin/env moon

argparse = require "argparse"


parser = with argparse nil, "QA tool for YunoRock’s recipes."
	with \command "html", "Produce a HTML summary of the recipes’ quality and status."
		\argument "directory", "Where to read the recipes from."

arguments = parser\parse!

lfs = require "lfs"
pkgxx = require "pkgxx"

RecipeSummary = class
	new: =>
		context = pkgxx.newContext {}
		@context = context

		context\importConfiguration "/etc/pkgxx.conf"

		-- For git-related things. FIXME: Consider removal or opt-in use.
		os.execute "mkdir -p .sources"
		context.sourcesDirectory = ".sources"

		context.logFile = io.open "check-recipes.log", "w"

		context\checkConfiguration!

		@recipes = {}

	loadDirectory: (dirname = ".") =>
		for entry in lfs.dir dirname
			if entry == "." or entry == ".."
				continue

			filepath = dirname .. "/" .. entry .. "/package.toml"

			unless lfs.attributes(filepath)
				continue

			success, recipe = pcall -> @context\openRecipe filepath

			unless success
				with reason = recipe
					io.stderr\write tostring(reason), "\n"
					continue

			status = "success"
			infos = {}
			errors = {}
			warnings = {}

			for field in *{"name", "sources", "url", "options", "watch"}
				unless recipe[field]
					status = "warnings"

			for field in *{"summary"}
				for package in *recipe.packages
					unless package[field]
						status = "warnings"
					break

			unless recipe.maintainer or recipe.packager
				status = "errors"

			if not recipe.version
				recipe\updateVersion!

			upToDate, lastVersion = recipe\isUpToDate!

			if recipe.watch
				-- FIXME: Things from git are not being watched correctly, here!
				--        We need to compare the latest version obtained to the latest versions built.
				--        That’s also true for non-development packages, but we have the latest release to at least know if the recipe’s outdated.
				if recipe.version
					if upToDate == false
						status = "info"
					elseif upToDate == nil
						status = "warning"

			recipe.upToDate = upToDate
			recipe.lastVersion = lastVersion

			status = if #errors > 0 or status == "errors"
				"errors"
			elseif #warnings > 0 or status == "warnings"
				"warnings"
			elseif #infos > 0 or status == "info"
				"info"
			else
				"success"

			table.insert @recipes, with recipe
				.upToDate = upToDate
				.lastVersion = lastVersion

				.status = status

				.infos = infos
				.warnings = warnings
				.errors = errors


if arguments.html
	{:render_html} = require "lapis.html"

	summary = with RecipeSummary!
		\loadDirectory arguments.directory

	io.write render_html ->
		div class: "section", ->
			div class: "container", ->
				div class: "columns is-multiline", ->
					for recipe in *summary.recipes
						colorClass = switch recipe.status
							when "success"
								"success"
							when "warnings"
								"warning"
							when "errors"
								"danger"
							else
								"info"

						div class: "column is-one-third", ->
							div class: "box has-ribbon", ->
								div class: "ribbon is-medium is-#{colorClass}", switch recipe.status
									when "info"
										"new data"
									else
										recipe.status
								div class: "title is-2", ->
									h3 recipe.name

								div class: "content", ->
									element "table", class: "table is-fullwidth", ->
										tr ->
											th "Version"
											td ->
												text "#{recipe.version or "(development)"}"
										tr ->
											th "Upstream ver."
											td ->
												if recipe.watch
													if recipe.version
														if recipe.upToDate == false
															span class: "tag is-info", "#{recipe.lastVersion} (outdated)"
														elseif recipe.upToDate == true
															span class: "tag is-success", "#{recipe.lastVersion}"
														else
															span class: "has-text-grey", "???"
													else
														span class: "has-text-grey", "(development)"
												else
													span class: "tag is-warning", "no [watch]"
										tr ->
											th "Release"
											td "#{recipe.release}"
										tr ->
											th "Maintainer"
											td ->
												if recipe.maintainer
													text recipe.maintainer
												else
													span class: "tag is-danger", "(missing maintainer)"
										tr ->
											th "Packager"
											td ->
												if recipe.packager
													text recipe.packager
												else
													span class: "tag is-danger", "(missing packager)"
										tr ->
											th "Homepage"
											td ->
												if recipe.url
													a href: recipe.url,"#{recipe.url}"
												else
													span class: "tag is-warning", "(missing url)"

									if recipe.options
										div class: "message", ->
											div class: "message-body has-text-centered", ->
												if#recipe.options > 0
													for option in *recipe.options
														colorClass = if option == "no-arch"
															"primary"
														else
															"info"

														span class: "tag is-#{colorClass}", option
												else
													text "no options"
									else
										div class: "message is-warning", ->
											div class: "message-body has-text-centered", ->
												raw "missing <code>options</code> field!"

									if #recipe.infos > 0
										div class: "message is-info content", ->
											div class: "message-header", "Information"
											div class: "message-body", ->
												for info in *recipe.infos
													p -> raw info

									if #recipe.errors > 0
										div class: "message is-danger content", ->
											div class: "message-header", "Errors"
											div class: "message-body", ->
												for error in *recipe.errors
													p -> raw error

									if #recipe.warnings > 0
										div class: "message is-warning content", ->
											div class: "message-header", "Warnings"
											div class: "message-body", ->
												for warning in *recipe.warnings
													p -> raw warning

									h4 class: "title is-4", "Generated packages:"
									for package in *recipe.packages
										div class: "message", ->
											div class: "message-header", ->
												text package.name

											element "table", class: "table", ->
												tr ->
													td "Target"
													td ->
														if package.version
															div class: "tag is-primary", package.target
														else
															text "???"

												tr ->
													td "Class"
													td ->
														-- class is non-essential
														if package.class
															div class: "tag is-primary", package.class
														else
															div class: "tag is-warning", package.class

												tr ->
													td "Summary"
													td ->
														if package.summary
															text package.summary
														else
															div class: "tag is-warning", "(no summary)"

	summary.context\close!

