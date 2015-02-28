module.exports = (app)->
	require! {
		'async'
		'lodash'
		'moment'
		'mongoose'
		'uuid'
		'winston'
	}
	_ = lodash
	ObjectId = mongoose.Types.ObjectId
	User = app.locals.models.User
	Course = app.locals.models.Course
	Post = app.locals.models.Post
	app
		..route '/:course/:blog(blog|b)/:unique?' # query action(new|edit|delete|deleteall)
		.all (req, res, next)->
			if req.query.action in ['new','edit','delete','deleteall']
				next!
			else
				next 'route'
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
							'faculty': ObjectId req.session.uid
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
			if req.query.action in ['edit','delete']
				if !req.params.unique?
					res.redirect "/#{res.locals.course.id}/blog"
				else
					err, result <- Post.find {
						'course': ObjectId res.locals.course._id
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
			switch req.query.action
			| 'new'
				res.render 'blog', { +create, on:'newblog', success:req.query.success, action:'created' }
			| 'edit'
				res.render 'blog', { +edit, on:'editblog', success:req.query.success, action:'updated' }
			| 'delete'
				res.render 'blog', { +del, on:'deleteblog', success:req.query.success, action:'deleted' }
		.post (req, res, next)->
			/* istanbul ignore else */
			if req.query.action is 'new'
				async.parallel [
					->
						if req.body.text? and req.body.text isnt "" and req.body.title? and req.body.title isnt ""
							res.render 'blog', { +create, 'blog':true, 'on':'newblog', success:'yes', action:'created' } # return
						else
							res.status 400 .render 'blog', { +create, 'blog':true, 'on':'newblog', success:'no', action:'created', body: req.body}
					->
						if req.body.text? and req.body.text isnt "" and req.body.title? and req.body.title isnt ""
							post = new Post {
								# uuid: res.locals.postuuid
								title: encodeURIComponent req.body.title
								text: req.body.text
								# files: req.body.files
								author: ObjectId req.session.uid
								authorName: req.session.firstName+" "+req.session.lastName
								authorUsername: req.session.username
								tags: []
								type: 'blog'
								school: app.locals.school
								course: ObjectId res.locals.course._id
							}
							err, post <- post.save
							/* istanbul ignore if */
							if err?
								winston.error 'blog post save', err
				]
			else
				next new Error 'bad blog post'
		.put (req, res, next)->
			if req.query.action is "edit"
				async.parallel [
					->
						if req.body.text? and req.body.text isnt "" and req.body.title? and req.body.title isnt ""
							res.redirect "/#{res.locals.course.id}/blog/#{req.params.unique}?action=edit&success=yes"
						else
							res.status 400 .render 'blog', { +create, blog:true, on:'editblog', success:'no', action:'updated', body: req.body}
					->
						if req.body.text? and req.body.text isnt "" and req.body.title? and req.body.title isnt ""
							err, post <- Post.findOneAndUpdate {
								'_id': ObjectId req.body.pid
								'school': app.locals.school
								'course': ObjectId res.locals.course._id
								'type': 'blog'
							}, {
								'title': req.body.title
								'text': req.body.text
							}
							/* istanbul ignore if */
							if err
								winston.error 'blog post update', err
				]
			else
				next new Error 'bad blog put'
		.delete (req, res, next)->
			if req.query.action in ["delete","deleteall"]
				async.parallel [
					->
						res.redirect "/#{res.locals.course.id}/blog?action=delete&success=yes"
					->
						if req.query.action is 'delete'
							err, post <- Post.remove {
								'_id': ObjectId req.body.pid
								'school': app.locals.school
								'course': ObjectId res.locals.course._id
								'type': 'blog'
							}
							/* istanbul ignore if */
							if err
								winston.error 'blog post delete', err
					->
						if req.query.action is 'deleteall' and req.params.unique?
							err, post <- Post.remove {
								'title': req.params.unique
								'school': app.locals.school
								'course': ObjectId res.locals.course._id
								'type': 'blog'
							}
							/* istanbul ignore if */
							if err
								winston.error 'blog post delete', err
				]
			else
				next new Error 'bad blog delete'
		..route '/:course/:blog(blog|b)/:unique?' # query action(search)
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
							'faculty': ObjectId req.session.uid
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
							'students': ObjectId req.session.uid
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
			# res.locals.blog = []
			if req.query.search? or req.params.unique?
				res.locals.search = if req.params.unique? then req.params.unique else req.query.search
				err, posts <- async.parallel [
					(done)->
						# search date
						if res.locals.search.split('...').length is 2
							date0 = new Date(res.locals.search.split('...').0)
							date1 = new Date(res.locals.search.split('...').1)
							if moment(date0).isValid! and moment(date1).isValid!
								err, posts <- Post.find {
									'course':ObjectId(res.locals.course._id)
									'type':'blog'
									# 'title':res.locals.search
									'timestamp':{
										$gte: date0
										$lt: date1
									}
								}
								done err,posts
							else
								done! # it's not a date range
						else
							done! # it's not a range
					(done)->
						# search text
						Post.find {
							'course': ObjectId(res.locals.course._id)
							'type': 'blog'
							'text': new RegExp res.locals.search, 'i'
						}, (err, posts)->
							done err, posts
					(done)->
						# search titles
						Post.find {
							'course': ObjectId(res.locals.course._id)
							'type': 'blog'
							'title': new RegExp res.locals.search, 'i'
						}, (err, posts)->
							done err, posts
					(done)->
						# search tags
						Post.find {
							'course': ObjectId(res.locals.course._id)
							'type': 'blog'
							'tags': res.locals.search
						}, (err, posts)->
							done err, posts
					(done)->
						# search authorName
						Post.find {
							'course': ObjectId(res.locals.course._id)
							'type': 'blog'
							'authorName': new RegExp res.locals.search, 'i'
						}, (err, posts)->
							done err, posts
				]
				posts = _.flatten _.without(posts,undefined), true
				posts = if posts.length > 0 then _.uniq _.sortBy(posts, 'timestamp').reverse!,(input)->
					return input.timestamp.toString!
				res.render 'blog', blog: posts
			else
				err, posts <- Post.find {
					'course': ObjectId res.locals.course._id
					'type':'blog'
				}
				res.locals.blog = _.sortBy posts, 'timestamp' .reverse!
				res.render 'blog'
