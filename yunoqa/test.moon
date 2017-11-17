
class
	new: (arg) =>
		@status =       arg.status or       "error"
		@directive =    arg.directive or    nil
		@number =       arg.number or       nil
		@description =  arg.description or  nil
		@comment =      arg.comment or      nil

		-- FIXME: Do a proper import. .yaml is good enough only for the TAP parser.
		@yaml = arg.yaml or nil

	__tostring: (test) =>
		"<yunoqa.Test: N°#{@number}, #{@description}>"

