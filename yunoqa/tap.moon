
yaml = require "lyaml"

_M = {}

---
-- Please do note that this TAP parser is not 100% complete and does not
-- implement all of TAP’s functionality.
--
-- Missing features include:
--   - Putting the number of tests ("1..X") at the beginning of the run.
--   - Textual diagnostics are ignored.
--   - Proper syntax errors.
---

parseDirective = (str) ->
	type, comment = str\match "^([a-zA-Z]*)(.*)"

	comment = comment\gsub "^%s*", ""

	switch type\lower!
		when "todo", "skip", "skipped"
			if type == "skipped"
				type = "skip"
			true
		else
			return "not ok", comment

	return type, comment

_M.parse = (tap) ->
	state = "preSuite"
	count = 0

	tests = {
		summary: {
			"ok":     0
			"not ok": 0
			"skip":   0
			"todo":   0
		}
	}

	for line in tap\gmatch "[^\n]*"
		switch state
			when "preSuite"
				version = line\match "TAP version ([0-9]+)"
				unless version
					continue

				version = tonumber version

				state = "preTests"
			when "preTests", "tests"
				if line\match "^# "
					line = line\gsub "^# *", ""

					if state == "preTests"
						if tests.heading
							tests.heading ..= "\n" .. line
						else
							tests.heading = line
					else
						print "??? 1 #{line}"
				elseif line\match("^ok ") or line\match("^not ok ")
					state = "tests"

					count += 1

					status = if line\match("^ok ")
						"ok"
					else
						"not ok"

					number, description, directive = line\match "#{status} ([0-9]+) *(.*) *# (.*)"

					unless number
						number, description = line\match "ok ([0-9]+) *(.*)"

					number = tonumber number

					description = description\gsub "^ *", ""
					description = description\gsub " *$", ""
					description = description\gsub "^ *%- *", ""

					if directive
						directive = directive\gsub "^ *", ""
						directive = directive\gsub " *$", ""

						if directive == ""
							directive = nil

						directive = directive\lower!

					directive, comment = if directive
						parseDirective directive

					if directive
						-- Pending tests are considered successes.
						-- "However, because the failing tests are marked as things to do later, they are considered successes. Thus, a harness should report this entire listing as a success."
						status = "ok"

					table.insert tests, {
						:status, :directive, :number
						:description, :comment
					}

					tests.summary[directive or status] += 1
				elseif line\match "^[0-9]+%.%.[0-9]+$"
					state = "postTests"
					one, max = line\match "^([0-9]+)%.%.([0-9]+)$"

					max = tonumber max

					-- FIXME: Proper error reporting. :(
					if max != count
						print "OH NOES"
				elseif line\match "^  %-%-%-"
					state = "inYAML"
				elseif line\match "^%s*$"
					true -- Ignoring whitespace, empty line.
				else
					io.stderr\write "??? 2 #{line}\n"
			when "inYAML"
				if line\match "^  "
					if line\match "^  %.%.%."
						latestTest = tests[#tests]
						latestTest.yaml = yaml.load latestTest.yaml
						state = "tests"
					else
						latestTest = tests[#tests]
						line = line\gsub "^  ", ""

						if latestTest
							if type(latestTest.yaml) == "string"
								latestTest.yaml ..= "\n" .. line
							else
								latestTest.yaml = line
						else
							print "YAML (no previous test): #{line}"
				elseif line\match "^%s*$"
					true -- Ignoring whitespace, empty line.
				else
					io.stderr\write "??? 3 #{line}\n"
			when "postTests"
				if line\match "^#"
					line = line\gsub "^# *", ""
					if tests.footer
						tests.footer ..= "\n" .. line
					else
						tests.footer = line
			else
				io.stderr\write "??? 4 #{line}\n"

	tests

_M

