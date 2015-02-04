module.exports = exports = (app)->
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
			switch req.body.type
			| 'Faculty'
				err,data <- models.Teacher.find { 'username':req.body.username, 'school':app.locals.school }
				if err?
					winston.error err
				if data[0]?
					faculty = data[0]
					err,result <- bcrypt.compare req.body.password, faculty.hash
					req.session.auth = 2
					winston.info data
					res.send data
					res.end!
				else
					winston.info err
			| 'Admin'
				err,data <- models.Admin.find { 'username':req.body.username, 'school':app.locals.school }
				winston.info 'c'
				if err?
					winston.error err
				if data[0]?
					admin = data[0]
					err,result <- bcrypt.compare req.body.password, student.hash
					if result is true
						req.session.auth = 3
						winston.info data
						res.redirect '/'
						res.end!
					else
						res.render 'login', { error:'login credentials not valid' }
				else
					res.render 'login', { error:'username not found' }
			#
			#	Might add sudo/su/root account for admins of admins
			#
			| _ # default to student login
				winston.info req.body
				err,data <- models.Student.find { 'username':req.body.username, 'school':app.locals.school }
				winston.info 'a'
				if err?
					winston.error err
				if data[0]?
					student = data[0]
					err,result <- bcrypt.compare req.body.password, student.hash
					req.session.auth = 1
					winston.info data
					res.send data
					res.end!
				else
					winston.info err
