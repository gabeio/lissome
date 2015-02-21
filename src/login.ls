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
			if req.session.auth? or req.session.userid? or req.session.username?
				res.redirect '/'
			else
				res.render 'login'
		.post (req, res, next)->
			if req.body.username? and req.body.username isnt "" and req.body.password? and req.body.password isnt ""
				err, user <- User.findOne {
					'username':req.body.username.toLowerCase!
					'school':app.locals.school
				}
				if err
					winston.err 'user:find', err
				if !user? or user.length is 0
					res.render 'login', { error: 'username not found' }
				else
					err,result <- bcrypt.compare req.body.password, user.hash
					if err
						winston.err err
					if result is true
						# do NOT take anything from req.body
						req.session.auth = user.type
						req.session.username = user.username
						req.session.userid = user.id
						req.session.uid = user._id
						req.session.firstName = user.firstName
						req.session.middleName = if user.middleName? then user.middleName
						req.session.lastName = user.lastName
						# req.session.courses = user.courses # find better way
						res.redirect '/'
					else
						res.render 'login', { error:'bad login credentials' }
			else
				res.render 'login', { error: 'bad login credentials' }
