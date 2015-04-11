module.exports = (app)->
	models = app.locals.models
	app
		..route "/admin/:object?"
		# object should be an ObjectId
		# ?action is what the user wishes to do:
		#   create, edit, delete, etc.
		# ?type is what model we are working with
		#   course, user, etc.
		.all (req, res, next)->
			res.locals.needs = 3
			app.locals.authorize req, res, next
		.all (req, res, next)->
			if req.query.action? then req.query.action = req.query.action.toLowerCase!
			next!
		.get (req, res, next)->
			switch req.query.action
			| "create"
				res.render "admin/create", {type:req.query.type}
			| "edit"
				res.render "admin/edit", {type:req.query.type}
			| "delete"
				res.render "admin/delete", {type:req.query.type}
			| _
				res.render "admin/default"
		.post (req, res, next)->
			switch req.query.action
			| "create"
				...
			| _
				next!
		.put (req, res, next)->
			switch req.query.action
			| "edit"
				...
			| _
				next!
		.delete (req, res, next)->
			switch req.query.action
			| "delete"
				...
			| _
				next!
