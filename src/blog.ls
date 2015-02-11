module.exports = (app)->
	require! {
		'uuid'
	}
	winston = app.locals.winston
	models = app.locals.models
	app
		..route '/:course/blog/:id?/edit'
		.all (req, res, next)->
			res.locals.needs = 2
			app.locals.authorize req, res, next
		.get (req, res, next)->
			err,blog <- models.Course.find { 'id':req.params.course, 'school':app.locals.school }
			if err?
				winston.error 'blog:find '+err
			if !blog? or blog.length is 0
				next new Error 'NOT FOUND'
			else
				res.locals.blog = blog.0.blog
				res.render 'blog', { +edit }
		.post (req, res, next)->
			post = new Post {
				uuid: uuid.v4!
				text: req.body.body
				files: ''
				author: req.session.username
				time: new Date Date.now!
			}
			err, post <- post.save
			winston.info post
			# err,blog <- models.Course.find { 'id':req.params.course, 'school':app.locals.school }
			# if err?
			# 	winston.error 'blog:find '+err
			# if !blog? or blog.length is 0
			# 	next new Error 'NOT FOUND'
			# else
			# 	err,blog <- models.Course.update { 'id':req.params.course, 'school':app.locals.school }, { 'blog': blog.0.blog }
			# 	if err?
			# 		winston.error 'blog:find '+err
			# 	if !blog? or blog.length is 0
			# 		next new Error 'NOT FOUND'
			# 	else
			# 		res.locals.blog = blog.0.blog
			# 		res.redner 'blog'
		.put (req, res, next)->
			...


		..route '/:course/blog/:id?'
		.all (req, res, next)->
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.get (req, res, next)->
			err,blog <- models.Course.find { 'id':req.params.course, 'school':app.locals.school }
			if err?
				winston.error 'blog:find '+err
			if !blog? or blog.length is 0
				next new Error 'NOT FOUND'
			else
				res.locals.blog = blog.0.blog
				res.render 'blog'
