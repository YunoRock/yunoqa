
_M = {}

{:render_html} = require "lapis.html"

headers = ->
	s = ""
	s ..= '<?xml-stylesheet href="style.css">\n'
	s ..= '<?xml version="1.0" encoding="utf-8"?>\n'
	s

renderCounts = (results) -> render_html ->
	count = {}
	for test in *results
		status = test.directive or test.status
		count[status] or= 0
		count[status] += 1

	for status in *{"ok", "not ok", "todo", "skip"}
		count[status] or= 0

		span class: "navbar-item", ->
			tagStyle = switch status
				when "ok"
					"is-success"
				when "not ok"
					"is-danger"
				when "skip"
					"is-primary"
				when "todo"
					"is-warning"
			span class: {"tag", "is-large", tagStyle}, ->
				text count[status]
			span class: {"tag", "is-dark", "is-medium"}, status

-- FIXME: First parameter should be whole configuration.
header = (suite, results) -> render_html ->
	div class: "navbar has-shadow", ->
		div class: "container", ->
			a class: "navbar-item", href: "//yunorock.netlib.re",
				"Home"
			a class: "navbar-item", href: "index.xhtml",
				"Quality Assurance"

			unless suite
				return

			a class: "navbar-item", href: "#{suite.project}.xhtml",
				suite.project

			if results
				a class: "navbar-item", href: "#{suite.project}-#{results.environmentName}-#{results.revisionName}.xhtml",
					results.revisionName

				div class: "navbar-end", ->
					raw renderCounts results
			else
				div class: "navbar-end", ->
					status = "ok" -- FIXME XXX
					okCount = 0
					for environment in *suite.environments
						latestTest = environment[1]

						if latestTest.summary["not ok"] == 0
							okCount += 1

					maxCount = #suite.environments

					successRatio = okCount / maxCount

					span class: "navbar-item", ->
						tagStyle, description = if successRatio == 1
							"is-success",  "all ok"
						elseif successRatio == 0
							"is-danger",  "all failed"
						else
							"is-warning",   "failures"

						span class: {"tag", "is-large", tagStyle}, ->
							text tostring okCount
							text " / "
							text tostring maxCount
						span class: {"tag", "is-dark", "is-medium"}, ->
							text description

_M.singleResultsPage = (results, project) ->
	s = headers!

	s ..= render_html ->
		html xmlns: "http://www.w3.org/1999/xhtml", "xml:lang": "en", lang:"en", ->
			head ->
			body ->
				raw header project, results

				div class: "section hero is-light is-small", ->
					div class: "container", ->
						div class: "columns is-centered", ->
							div class: "column is-half", ->
								h3 class: "title is-1", project.name
				br!
				div class: "container", ->
					div class: "columns is-centered", ->
						div class: "column is-half", ->
							if results.heading
								h3 class: "title is-3", results.heading
							ul ->
								for test in *results
									li class: "media", ->
										status = test.directive or test.status
										statusStyle = switch status
											when "ok"
												"is-success"
											when "not ok"
												"is-danger"
											when "skip"
												"is-primary"
											when "todo"
												"is-warning"

										div class: "media-left", ->
											span class: "tag is-medium is-dark", test.number
											span class: {statusStyle, "tag", "is-medium"}, status
										div class: "media-content", ->
											span test.description

											if test.yaml and test.yaml.message
												pre -> code test.yaml.message

										if test.yaml
											div class: "media-right", ->
												duration = test.yaml.duration

												if duration
													text string.format("%.3f", duration * 1000)
													text " ms"
							if results.footer
								pre -> code results.footer

	s

_M.projectResultsPage = (project) ->
	s = headers!

	s ..= render_html ->
		html xmlns: "http://www.w3.org/1999/xhtml", "xml:lang": "en", lang:"en", ->
			head ->
			body ->
				raw header project

				div class: "section hero is-light is-small", ->
					div class: "container", ->
						div class: "columns is-centered", ->
							div class: "column is-half", ->
								h3 class: "title is-1", project.project
				br!
				div class: "container", ->
					div class: "columns is-centered", ->
						div class: "column is-half", ->
							h3 class: "title is-3", "Per-environment summary"
							ul ->
								for environment in *project.environments
									li class: "columns", ->
										div class: "column",
											environment.name

										latestTest = environment[1]
										div class: "column is-3 has-text-center", ->
											if latestTest.summary["not ok"] != 0
												span class: "tag is-medium is-danger", "not ok"
											else
												span class: "tag is-medium is-success", "ok"

							h3 class: "title is-3", "Latest results registered"
							ul ->
								for index, results in ipairs project.results
									environment = do
										_R = nil
										for env in *project.environments
											if env.name == results.environmentName
												_R = env
												break
										_R

									-- FIXME: inline style
									style = if results == environment[1]
										"background-color: #BBB;"

									li class: {"columns"}, style: style, ->
										-- FIXME: inline CSS
										div class: "column is-2", style: "width: 12.5%;", ->
											if results.summary["not ok"] > 0
												span class: "tag is-medium is-danger", "failed"
											else
												span class: "tag is-medium is-success", "success"

										div class: "column is-fullwidth", ->
											a href: "#{project.project}-#{results.environmentName}-#{results.revisionName}.xhtml", ->
												div class: "title is-6", ->
													code results.revisionName
												div class: "subtitle is-5", ->
													text results.environmentName
													text " - "
													text results.date

										div class: "column is-3", ->
											span class: "tag is-medium is-success", results.summary["ok"]
											span class: "tag is-medium is-danger", results.summary["not ok"]
											span class: "tag is-medium is-primary", results.summary["skip"]
											span class: "tag is-medium is-warning", results.summary["todo"]

	s

_M.indexPage = (configuration) ->
	s = headers!

	s ..= render_html ->
		html xmlns: "http://www.w3.org/1999/xhtml", "xml:lang": "en", lang:"en", ->
			head ->
			body ->
				raw header!

				div class: "section hero is-light is-small", ->
					div class: "container", ->
						div class: "columns is-centered", ->
							div class: "column is-half", ->
								h3 class: "title is-1", "YunoRock Quality Assurance"
				br!
				div class: "container", ->
					div class: "columns is-centered", ->
						div class: "column is-half", ->
							ul ->
								for project in *configuration.projects
									total = 0
									notOk = 0

									for environment in *project.environments
										latestTest = environment[1]

										total += 1

										if latestTest.summary["not ok"] > 0
											notOk += 1

									li class: "media", ->
										div class: "media-content", ->
											span class: "title is-4", ->
												a href: "#{project.project}.xhtml", project.project

										styleClass, comment = if notOk == 0
											"is-success", "ok"
										elseif notOk == total
											"is-danger", "not ok"
										else
											"is-warning", "not ok"

										span class: "media-right", ->
											span class: {"tag", "is-large", styleClass}, comment

	s

_M

