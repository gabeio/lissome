module.exports = (app)->
	require! {
		'bcrypt'
		'winston'
	}
	# winston = app.locals.winston
	# models = app.locals.models
	User = app.locals.models.User
	app
		..route '/login'
		.get (req, res, next)->
			if res.locals.auth? or res.locals.userid? or res.locals.username?
				res.redirect '/'
			else
				res.render 'login'
		.post (req, res, next)->
			if req.body.username? and req.body.username isnt "" and req.body.password? and req.body.password isnt ""
				err, user <- User.findOne {
					'username':req.body.username.toLowerCase!
					'school':app.locals.school
				}
				/* istanbul ignore if */
				if err
					winston.err 'user:find', err
				if !user? or user.length is 0
					res.render 'login', { error: 'username not found' }
				else
					err,result <- bcrypt.compare req.body.password, user.hash
					/* istanbul ignore if */
					if err
						winston.err err
					if result is true
						# do NOT take anything from req.body
						res.locals.auth = user.type
						res.locals.username = user.username
						res.locals.userid = user.id
						res.locals.uid = user._id
						res.locals.firstName = user.firstName
						/* istanbul ignore next */
						# res.locals.middleName = if user.middleName? then user.middleName
						res.locals.lastName = user.lastName
						res.redirect '/'
					else
						res.render 'login', { error:'bad login credentials' }
			else
				res.render 'login', { error: 'bad login credentials' }
