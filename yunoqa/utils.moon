
{:mkdir} = require "lfs"

_M = {}

_M.split_string = (str, pattern) ->
	st, g = 1, str\gmatch "()(" .. pattern .. ")"

	getter = (segs, separators, separator, cap1, ...) =>
		st = separator and separators + #separator

		str\sub(segs, (separators or 0) - 1), cap1 or separator, ...

	splitter = =>
		getter(str, st, g!) if st

	splitter, str


_M.mkdir_p = (path) ->
	local current

	for dir in _M.split_string path, "/"
		current = if current
			table.concat({current, dir}, "/")
		else
			dir

		mkdir current

_M

