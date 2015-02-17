module.exports = (app)->
	require! {
		'mongoose'
		'winston'
	}
	Course = app.locals.models.Course
	Post = app.locals.models.Post
	app
		..route '/:course/edit'
		.all (req, res, next)->
			res.locals.needs = 2 # maybe 3
			app.locals.authorize req, res, next
		.all (req, res, next)->
			res.locals.oncourse = true
			...
		.get (req, res, next)->
			res.send 'this will allow showing of course settings'
			/*
			err,result <- Course.find { 'id':req.params.course, 'school':app.locals.school }
			if err?
				winston.error err
			if !result[0]?
				next new Error 'NOT FOUND'
			else
				res.send result
			*/
		.post (req, res, next)->
			next new Error 'NOT IMPL'
			/*
			err,result <- Course.update { 'id':req.params.course, 'school':app.locals.school }, {}
			if err?
				winston.error err
			if !result[0]?
				next new Error 'NOT FOUND'
			else
				res.send result
			*/

		..route '/:course/:index(index|dash|dashboard)?'
		.all (req, res, next)->
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.get (req, res, next)->
			res.locals.oncourse = true
			switch req.session.auth
			| 1
				console.log '1'
				err,result <- Course.find { 'id':req.params.course, 'school':app.locals.school, 'students': mongoose.Types.ObjectId(req.session.uid) }
				if err?
					winston.error 'course:find', err
					next new Error 'INTERNAL'
				else
					if !result? or result.length is 0
						next new Error 'NOT FOUND'
					else
						res.locals.course = result.0
						next!
			| 2
				console.log '2'
				err,result <- Course.find { 'id':req.params.course, 'school':app.locals.school, 'faculty': mongoose.Types.ObjectId(req.session.uid) }
				if err?
					winston.error 'course:find', err
					next new Error 'INTERNAL'
				else
					if !result? or result.length is 0
						next new Error 'NOT FOUND'
					else
						res.locals.course = result.0
						next!
			| 3
				console.log '3'
				err,result <- Course.find { 'id':req.params.course, 'school':app.locals.school }
				if err?
					winston.error 'course:find', err
					next new Error 'INTERNAL'
				else
					if !result? or result.length is 0
						next new Error 'NOT FOUND'
					else
						res.locals.course = result.0
						next!
			| _
				next new Error 'UNAUTHORIZED'
		.get (req, res, next)->
			console.log '4'
			res.render 'course'
