module.exports = (app)->
	require! {
		'bcrypt'
	}
	winston = app.locals.winston
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
			err, user <- User.find { 'username':req.body.username.toLowerCase!, 'school':app.locals.school }
			if err
				winston.err 'user:find', err
			if !user? or user.length is 0
				res.render 'login', { error: 'username not found' }
			else
				user = user.0
				err,result <- bcrypt.compare req.body.password, user.hash
				if err
					winston.err err
				if result is true
					# do NOT take anything from req.body
					req.session.auth = user.type
					req.session.username = user.username
					req.session.userid = user.id
					req.session.courses = user.courses
					res.redirect '/'
					res.end!
				else
					res.render 'login', { error:'bad login credentials' }
