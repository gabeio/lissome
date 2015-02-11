module.exports = (app)->
	require! {
		'bcrypt'
	}
	winston = app.locals.winston
	models = app.locals.models
	app
		..route '/login'
		.get (req, res, next)->
			if req.session.auth? or req.session.userid? or req.session.username?
				res.redirect '/'
			else
				res.render 'login'
		.post (req, res, next)->
			if !req.body.type? then req.body.type = 'unknown' # user type
			switch req.body.type.toLowerCase!
			| 'faculty'
				err,faculty <- models.Faculty.find { 'username':req.body.username.toLowerCase!, 'school':app.locals.school }
				/* istanbul ignore next errors really shouldn't ever happen while connection is open */
				if err?
					winston.error 'faculty:find '+err
				if !faculty? or faculty.length is 0
					res.render 'login', { error:'username not found' }
				else
					faculty = faculty[0]
					err,result <- bcrypt.compare req.body.password, faculty.hash
					if err
						winston.err err
					if result is true
						req.session.auth = 2
						req.session.username = req.body.username.toLowerCase!
						req.session.userid = faculty.id
						res.redirect '/'
						res.end!
					else
						res.render 'login', { error:'bad login credentials' }
			| 'admin'
				err,admin <- models.Admin.find { 'username':req.body.username.toLowerCase!, 'school':app.locals.school }
				/* istanbul ignore next errors really shouldn't ever happen while connection is open */
				if err?
					winston.error 'admin:find '+err
				if !admin? or admin.length is 0
					res.render 'login', { error:'username not found' }
				else
					admin = admin[0]
					err,result <- bcrypt.compare req.body.password, admin.hash
					if err
						winston.err err
					if result is true
						req.session.auth = 3
						req.session.username = req.body.username.toLowerCase!
						req.session.userid = admin.id
						res.redirect '/'
						res.end!
					else
						res.render 'login', { error:'bad login credentials' }
			| _ # default to student login
				if req.body.type.toLowerCase! isnt 'student' then winston.info req.body
				err,student <- models.Student.find { 'username':req.body.username.toLowerCase!, 'school':app.locals.school }
				/* istanbul ignore next errors really shouldn't ever happen while connection is open */
				if err?
					winston.error 'student:find '+err
				if !student? or student.length is 0
					res.render 'login', { error:'username not found' }
				else
					student = student[0]
					err,result <- bcrypt.compare req.body.password, student.hash
					if err
						winston.err err
					if result is true
						req.session.auth = 1
						req.session.username = req.body.username.toLowerCase!
						req.session.userid = student.id
						res.redirect '/'
						res.end!
					else
						res.render 'login', { error:'bad login credentials' }
