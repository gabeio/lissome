module.exports = (app)->
	require! {
		'async'
		'lodash'
		'mongoose'
		'uuid'
		'winston'
	}
	_ = lodash
	User = app.locals.models.User
	Course = app.locals.models.Course
	Post = app.locals.models.Post
	app
		..route '/:course/:blog(blog|b)/:action(new|edit|delete|deleteall)/:unique?'
		.all (req, res, next)->
			res.locals.needs = 2
			app.locals.authorize req, res, next
		.all (req, res, next)->
			res.locals.on = 'blog'
			<- async.parallel [
				(done)->
					if req.session.auth is 3
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
						}
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:blog:auth3', err
							next new Error 'INTERNAL'
						else
							/* istanbul ignore if */
							if !result? or result.length is 0
								next new Error 'NOT FOUND'
							else
								res.locals.course = result
								done!
					else
						done!
				(done)->
					if req.session.auth is 2
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
							'faculty': mongoose.Types.ObjectId req.session.uid
						}
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:blog:auth2', err
							next new Error 'INTERNAL'
						else
							/* istanbul ignore if */
							if !result? or result.length is 0
								next new Error 'NOT FOUND'
							else
								res.locals.course = result
								done!
					else
						done!
			]
			next!
		.get (req, res, next)->
			if req.params.action in ['edit','delete']
				if !req.params.unique?
					res.redirect "/#{res.locals.course.id}/blog"
				else
					err, result <- Post.find {
						'course': mongoose.Types.ObjectId(res.locals.course._id)
						'type': 'blog'
						'title': req.params.unique
					}
					if result.length is 0
						res.redirect "/#{res.locals.course.id}/blog"
					else
						res.locals.posts = if result.length isnt 0 then _.sortBy result, 'timestamp' .reverse! else []
						next!
			else
				next!
		.get (req, res, next)->
			res.locals.blog = true
			switch req.params.action
			| 'new'
				res.render 'blog', { +create, on:'newblog' }
			| 'edit'
				res.render 'blog', { on:'editblog', edit:true }
			| 'delete'
				res.render 'blog', { on:'deleteblog', del:true }
		.post (req, res, next)->
			var authorName, authorUsername
			/* istanbul ignore else */
			if req.params.action is 'new'
				async.parallel [
					->
						if req.body.text? and req.body.text isnt "" and req.body.title? and req.body.title isnt ""
							res.render 'blog', { +create, 'blog':true, 'on':'newblog', success:'yes' } # return
						else
							res.status 400 .render 'blog', { +create, 'blog':true, 'on':'newblog', success:'no', stuff: req.body}
					->
						if req.body.text? and req.body.text isnt "" and req.body.title? and req.body.title isnt ""
							authorUsername := req.session.username
							authorName := req.session.firstName+" "+req.session.lastName
							post = new Post {
								# uuid: res.locals.postuuid
								title: encodeURIComponent req.body.title
								text: req.body.text
								# files: req.body.files
								author: mongoose.Types.ObjectId req.session.uid
								authorName: authorName
								authorUsername: authorUsername
								tags: []
								type: 'blog'
								school: app.locals.school
								course: mongoose.Types.ObjectId res.locals.course._id
							}
							err, post <- post.save
							/* istanbul ignore if */
							if err?
								winston.error 'blog post save', err
				]
			else
				next new Error 'probably edit gone awry'
		.put (req, res, next)->
			async.parallel [
				->
					if req.body.text? and req.body.text isnt "" and req.body.title? and req.body.title isnt ""
						res.redirect "/#{res.locals.course.id}/blog/edit/#{req.params.unique}"
					else
						res.status 400 .render 'blog', { +create, 'blog':true, 'on':'editblog', success:'no', stuff: req.body}
				->
					if req.body.text? and req.body.text isnt "" and req.body.title? and req.body.title isnt ""
						err, post <- Post.findOneAndUpdate {
							'_id': mongoose.Types.ObjectId req.body.pid
							'school': app.locals.school
							'course': mongoose.Types.ObjectId res.locals.course._id
							'type': 'blog'
						}, {
							'title': req.body.title
							'text': req.body.text
						}
						/* istanbul ignore if */
						if err
							winston.error 'blog post update', err
			]
		.delete (req, res, next)->
			async.parallel [
				->
					res.redirect "/#{res.locals.course.id}/blog"
				->
					if req.params.action is "delete"
						err, post <- Post.remove {
							'_id': mongoose.Types.ObjectId req.body.pid
							'school': app.locals.school
							'course': mongoose.Types.ObjectId res.locals.course._id
							'type': 'blog'
						}
						/* istanbul ignore if */
						if err
							winston.error 'blog post delete', err
				->
					if req.params.action is "deleteall" and req.params.unique?
						err, post <- Post.remove {
							'title': req.params.unique
							'school': app.locals.school
							'course': mongoose.Types.ObjectId res.locals.course._id
							'type': 'blog'
						}
						/* istanbul ignore if */
						if err
							winston.error 'blog post delete', err
			]
		..route '/:course/:blog(blog|b)/:action(search)?/:unique?'
		.all (req, res, next)->
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.all (req, res, next)->
			res.locals.on = 'blog'
			<- async.parallel [
				(done)->
					if req.session.auth is 3
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
						}
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:blog:auth3', err
							next new Error 'INTERNAL'
						else
							/* istanbul ignore if */
							if !result? or result.length is 0
								next new Error 'NOT FOUND'
							else
								res.locals.course = result
								done!
					else
						done!
				(done)->
					if req.session.auth is 2
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
							'faculty': mongoose.Types.ObjectId req.session.uid
						}
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:blog:auth2', err
							next new Error 'INTERNAL'
						else
							/* istanbul ignore if */
							if !result? or result.length is 0
								next new Error 'NOT FOUND'
							else
								res.locals.course = result
								done!
					else
						done!
				(done)->
					if req.session.auth is 1
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
							'students': mongoose.Types.ObjectId req.session.uid
						}
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:blog:auth1', err
							next new Error 'INTERNAL'
						else
							/* istanbul ignore if */
							if !result? or result.length is 0
								next new Error 'NOT FOUND'
							else
								res.locals.course = result
								done!
					else
						done!
			]
			next!
		.get (req, res, next)->
			res.locals.blog = []
			if req.params.action is 'search' and req.params.unique?
				err, posts <- async.parallel [
					# (done)->
					# 	# search date
					# 	if moment(req.params.unique).isValid!
					# 		err, posts <- Post.find {
					# 			'course':mongoose.Types.ObjectId(res.locals.course._id)
					# 			'type':'blog'
					# 			'title':req.params.unique
					# 		}
					# 		for post in posts
					# 			res.locals.blog.push post
					# 		done!
					# 	# if it's not a date don't do the search
					(done)->
						# search titles
						Post.find {
							'course': mongoose.Types.ObjectId(res.locals.course._id)
							'type': 'blog'
							'text': new RegExp req.params.unique, 'i'
						}, (err, posts)->
							done err, posts
					(done)->
						# search titles
						Post.find {
							'course': mongoose.Types.ObjectId(res.locals.course._id)
							'type': 'blog'
							'title': new RegExp req.params.unique, 'i'
						}, (err, posts)->
							done err, posts
					(done)->
						# search tags
						Post.find {
							'course': mongoose.Types.ObjectId(res.locals.course._id)
							'type': 'blog'
							'tags': req.params.unique
						}, (err, posts)->
							done err, posts
					(done)->
						# search authorName
						Post.find {
							'course': mongoose.Types.ObjectId(res.locals.course._id)
							'type': 'blog'
							'authorName': new RegExp req.params.unique, 'i'
						}, (err, posts)->
							done err, posts
				]
				posts = _.flatten posts, true
				posts = if posts.length isnt 0 then _.sortBy posts, 'timestamp' .reverse!
				res.render 'blog', blog: posts
			else
				err, posts <- Post.find {
					'course': mongoose.Types.ObjectId res.locals.course._id
					'type':'blog'
				}
				res.locals.blog = _.sortBy posts, 'timestamp' .reverse!
				res.render 'blog'
