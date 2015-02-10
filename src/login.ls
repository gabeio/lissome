module.exports = (app)->
	require! {
		'bcrypt'
	}
	winston = app.locals.winston
	models = app.locals.models
	app
		..route '/login'
		.get (req, res, next)->
			res.render 'login'
		.post (req, res, next)->
			if !req.body.type? then req.body.type = 'unknown' # user type
			switch req.body.type.toLowerCase!
			| 'faculty'
				err,data <- models.Faculty.find { 'username':req.body.username.toLowerCase!, 'school':app.locals.school }
				if err?
					winston.error 'faculty:find '+err
				if !data? or data.length is 0
					res.render 'login', { error:'username not found' }
				else
					faculty = data[0]
					err,result <- bcrypt.compare req.body.password, faculty.hash
					if err
						winston.err err
					if result is true
						req.session.auth = 2
						# winston.info data
						# res.send data
						res.redirect '/'
						res.end!
					else
						res.render 'login', { error:'bad login credentials' }
			| 'admin'
				err,data <- models.Admin.find { 'username':req.body.username.toLowerCase!, 'school':app.locals.school }
				if err?
					winston.error 'admin:find '+err
				if !data? or data.length is 0
					res.render 'login', { error:'username not found' }
				else
					admin = data[0]
					err,result <- bcrypt.compare req.body.password, admin.hash
					if err
						winston.err err
					if result is true
						req.session.auth = 3
						# winston.info data
						res.redirect '/'
						res.end!
					else
						res.render 'login', { error:'bad login credentials' }
			| _ # default to student login
				if req.body.type.toLowerCase! isnt 'student' then winston.info req.body
				err,data <- models.Student.find { 'username':req.body.username.toLowerCase!, 'school':app.locals.school }
				if err?
					winston.error 'student:find '+err
				if !data? or data.length is 0
					res.render 'login', { error:'username not found' }
				else
					student = data[0]
					err,result <- bcrypt.compare req.body.password, student.hash
					if err
						winston.err err
					if result is true
						req.session.auth = 1
						# winston.info data
						# res.send data
						res.redirect '/'
						res.end!
					else
						res.render 'login', { error:'bad login credentials' }
