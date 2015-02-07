module.exports = (app)->
	require! {
		'bcrypt'
	}
	winston = app.locals.winston
	models = app.locals.models
	app
		..route '/login'
		.get (req, res, next)->
			# res.send 'base:login > '+JSON.stringify req.params
			res.render 'login'
		.post (req, res, next)->
			if !req.body.type? then req.body.type = 'unknown'
			switch req.body.type.toLowerCase!
			| 'faculty'
				err,data <- models.Faculty.find { 'username':req.body.username, 'school':app.locals.school }
				if err?
					winston.error err
				if data[0]?
					faculty = data[0]
					err,result <- bcrypt.compare req.body.password, faculty.hash
					if result is true
						req.session.auth = 2
						# winston.info data
						# res.send data
						res.redirect '/'
						res.end!
					else
						res.render 'login', { error:'bad login credentials' }
				else
					res.render 'login', { error:'username not found' }
			| 'admin'
				err,data <- models.Admin.find { 'username':req.body.username, 'school':app.locals.school }
				winston.info 'c'
				if err?
					winston.error err
				if data[0]?
					admin = data[0]
					err,result <- bcrypt.compare req.body.password, admin.hash
					if result is true
						req.session.auth = 3
						# winston.info data
						res.redirect '/'
						res.end!
					else
						res.render 'login', { error:'bad login credentials' }
				else
					res.render 'login', { error:'username not found' }
			| _ # default to student login
				winston.info req.body
				err,data <- models.Student.find { 'username':req.body.username, 'school':app.locals.school }
				winston.info 'a'
				if err?
					winston.error err
				if data[0]?
					student = data[0]
					err,result <- bcrypt.compare req.body.password, student.hash
					if result is true
						req.session.auth = 1
						# winston.info data
						# res.send data
						res.redirect '/'
						res.end!
					else
						res.render 'login', { error:'bad login credentials' }
				else
					res.render 'login', { error:'username not found' }
