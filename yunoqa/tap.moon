
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

TAPInvalidCount = class
	new: (max, count) =>
		@max = max
		@count = count
		@type = "TAPInvalidCount"
		@message = "number of tests does not match header or footer"

	__tostring: =>
		"#{@message}: max=#{@max}, count=#{@count}"

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

parseTests = (tests, line, state, count) ->
	local max

	if line\match "^# "
		if state == "preTests"
			line = line\gsub "^# *", ""

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
		one, newMax = line\match "^([0-9]+)%.%.([0-9]+)$"

		newMax = tonumber newMax

		max = newMax

		unless state == "preTests"
			state = "postTests"
	elseif line\match "^  %-%-%-"
		state = "inYAML"
	elseif line\match "^%s*$"
		true -- Ignoring whitespace, empty line.
	else
		io.stderr\write "??? 2 #{line}\n"

	state, count, max

_M.parse = (tap) ->
	state = "preSuite"
	count = 0
	max = 0

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
					state = "preTests"
					state, count, newMax = parseTests tests, line, state, count
					max = newMax if newMax
					continue

				version = tonumber version

				state = "preTests"
			when "preTests", "tests"
				state, count, newMax = parseTests tests, line, state, count
				max = newMax if newMax
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

	if max != count
		error (TAPInvalidCount max, count), 0

	tests

_M

