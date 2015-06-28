module.exports = (app)->
	require! {
		"read-package-json"
	}
	app
		..route "/versions"
		.all (req, res, next)->
			console.log "a"
			next!
		# .all (req, res, next)->
		# 	res.locals.needs = 7
		# 	app.locals.authorize req, res, next
		.get (req, res, next)->
			read-package-json './package.json', console.error, false, (er, data)->
				if er
					console.error "There was an error reading the file"
					return
				# console.log data.dependencies
				# res.send data.dependencies
				res.render "versions", {packages: data.dependencies}
