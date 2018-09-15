
_M = {}

{:render_html} = require "lapis.html"

headers = ->
	s = ""
	s ..= '<?xml-stylesheet href="https://cdnjs.cloudflare.com/ajax/libs/bulma/0.7.1/css/bulma.min.css">\n'
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

header = (configuration, suite, results) -> render_html ->
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
				a class: "navbar-item", href: "#{suite.project}-#{results.date\gsub ":", "-"}-#{results.environmentName}-#{results.revisionName}.xhtml",
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

_M.basePage = (configuration, opt, content) ->
	unless content
		content = opt
		opt = {}

	s = headers!

	s ..= render_html ->
		html xmlns: "http://www.w3.org/1999/xhtml", "xml:lang": "en", lang:"en", ->
			head ->
			body ->
				raw header configuration, opt.project, opt.suite

				div class: "section hero is-light is-small", ->
					div class: "container", ->
						div class: "columns is-centered", ->
							div class: "column is-8", ->
								h3 class: "title is-1", tostring configuration.title
				br!
				div class: "container", ->
					raw render_html content
	s

_M.testsList = (results) -> render_html ->
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
					span class: "tags has-addons", ->
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

_M.singleResultsPage = (configuration, results, project) ->
	_M.basePage configuration, {project: project, suite: results}, ->
		div class: "section hero is-bold is-small", ->
			div class: "container", ->
				colorClass = if results.summary["not ok"] == 0
					""
				else
					"is-warning"

				div class: "message #{colorClass}", ->
					div class: "message-body", ->
						div class: "tags has-addons", ->
							div class: "tag is-big is-primary", "Duration"
							div class: "tag is-big is-info", ->
								if results.duration
									text string.format("%.3f", results.duration * 1000)
									text " ms"
								else
									text "unknown"

						div class: "tags has-addons", ->
							div class: "tag is-big is-primary", "Tests"
							div class: "tag is-big is-info",  tostring #results

						div class: "tags has-addons", ->
							statusString, colorClass = if results.summary["not ok"] == 0
								"all passed", "is-success"
							else
								"errors", "is-danger"

							div class: "tag is-big is-primary", "Status"
							div class: "tag is-big #{colorClass}", statusString

						div class: "tags has-addons", ->
							all = results.summary.ok + results.summary["not ok"]
							rate = 100 * results.summary.ok / all

							colorClass = if rate < 30
								"is-danger"
							elseif rate < 99
								"is-warning"
							else
								"is-success"

							div class: "tag is-big is-primary", ->
								text "Success rate"

							div class: "tag is-big #{colorClass}", ->
								text string.format "%.1f", rate
								text " %"
		br!
		div class: "container", ->
			div class: "columns is-centered", ->
				div class: "column is-8", ->
					if results.heading
						h3 class: "title is-3", results.heading
					raw _M.testsList results
					if results.footer
						pre -> code results.footer

_M.projectResultsPage = (configuration, project) ->
	_M.basePage configuration, project: project, ->
		div class: "columns is-centered", ->
			div class: "column is-8", ->
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

						li class: "media", ->
							div class: "media-content", ->
								div class: {"columns"}, ->
									div class: "column is-narrow", ->
										if results.summary["not ok"] > 0
											span class: "tag is-medium is-danger", "✗"
										else
											span class: "tag is-medium is-success", "✓"

									div class: "column is-fullwidth", ->
										a href: "#{project.project}-#{results.date\gsub ":", "-"}-#{results.environmentName}-#{results.revisionName}.xhtml", ->
											div class: {"title", "is-5"}, ->
												code results.revisionName
												text " - "
												code results.environmentName
												if results == environment[1]
													text " - "
													span class: "tag is-info", "Latest"
											div class: "subtitle is-5", ->
												text results.date

									div class: "column is-4", ->
										span class: "tag is-medium is-success", results.summary["ok"]
										span class: "tag is-medium is-danger", results.summary["not ok"]
										span class: "tag is-medium is-primary", results.summary["skip"]
										span class: "tag is-medium is-warning", results.summary["todo"]

_M.indexPage = (configuration) ->
	_M.basePage configuration, ->
		div class: "columns is-centered", ->
			div class: "column is-8", ->
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

_M

