require! {
	"express"
	"async"
	"lodash"
	"moment"
	"mongoose"
	"winston"
	"../app"
}
parser = app.locals.multer.fields []
ObjectId = mongoose.Types.ObjectId
_ = lodash
Post = mongoose.models.Post
router = express.Router!
router
	..route "/:unique?" # query action(new|edit|delete|deleteall)
	.all (req, res, next)->
		if req.query.action in ["new","edit","delete","deleteall"]
			next!
		else
			next "route"
	.all (req, res, next)->
		res.locals.needs = 2
		app.locals.authorize req, res, next
	.get (req, res, next)->
		if req.query.action in ["edit","delete"]
			if !req.params.unique?
				res.redirect "/c/#{res.locals.course._id}/blog"
			else
				err, result <- Post.find {
					"course": ObjectId res.locals.course._id
					"type": "blog"
					"title": req.params.unique
				} .populate "author" .exec
				if result.length is 0
					res.redirect "/c/#{res.locals.course._id}/blog"
				else
					/* istanbul ignore next else because it's hard to test for */
					res.locals.posts = if result.length isnt 0 then _.sortBy result, "timestamp" .reverse! else []
					next!
		else
			next!
	.get (req, res, next)->
		res.locals.blog = true
		switch req.query.action
		| "new"
			res.render "course/blog/create", { on:"newblog", success:req.query.success, action:"created", csrf: req.csrfToken! }
		| "edit"
			res.render "course/blog/edit", { on:"editblog", success:req.query.success, action:"updated", csrf: req.csrfToken! }
		| "delete"
			res.render "course/blog/del", { on:"deleteblog", success:req.query.success, action:"deleted", csrf: req.csrfToken! }
	.post parser (req, res, next)->
		/* istanbul ignore else */
		if req.query.action is "new"
			async.parallel [
				->
					if !req.body.text? or req.body.text is "" or !req.body.title? or req.body.title is ""
						res.status 400 .render "course/blog/create", { "blog":true, "on":"newblog", success:"no", action:"created", body: req.body, csrf: req.csrfToken! }
					else
						res.status 302 .redirect "/c/#{res.locals.course._id}/blog/"
				->
					if req.body.text? and req.body.text isnt "" and req.body.title? and req.body.title isnt ""
						post = new Post {
							title: encodeURIComponent req.body.title
							text: req.body.text
							# files: req.body.files
							author: ObjectId res.locals.uid
							tags: []
							type: "blog"
							school: app.locals.school
							course: ObjectId res.locals.course._id
						}
						err, post <- post.save
						/* istanbul ignore if */
						if err?
							winston.error "blog post save", err
			]
		else
			next new Error "bad blog post"
	.put parser (req, res, next)->
		if req.query.action is "edit"
			async.parallel [
				->
					if req.body.text? and req.body.text isnt "" and req.body.title? and req.body.title isnt ""
						res.redirect "/c/#{res.locals.course._id}/blog/#{req.params.unique}?action=edit&success=yes"
					else
						res.status 400 .render "course/blog/create", { blog:true, on:"editblog", success:"no", action:"updated", body: req.body, csrf: req.csrfToken! }
				->
					if req.body.text? and req.body.text isnt "" and req.body.title? and req.body.title isnt ""
						err, post <- Post.findOneAndUpdate {
							"_id": ObjectId req.body.pid
							"course": ObjectId res.locals.course._id
							"type": "blog"
						}, {
							"title": req.body.title
							"text": req.body.text
						}
						/* istanbul ignore if */
						if err
							winston.error "blog post update", err
			]
		else
			next new Error "bad blog put"
	.delete parser (req, res, next)->
		if req.query.action in ["delete","deleteall"]
			async.parallel [
				->
					res.redirect "/c/#{res.locals.course._id}/blog?action=delete&success=yes"
				->
					if req.query.action is "delete"
						err, post <- Post.findOneAndRemove {
							"_id": ObjectId req.body.pid
							"course": ObjectId res.locals.course._id
							"type": "blog"
						}
						/* istanbul ignore if */
						if err
							winston.error "blog post delete", err
				->
					if req.query.action is "deleteall" and req.params.unique?
						err, post <- Post.remove {
							"title": req.params.unique
							"course": ObjectId res.locals.course._id
							"type": "blog"
						}
						/* istanbul ignore if */
						if err
							winston.error "blog post delete", err
			]
		else
			next new Error "bad blog delete"

	..route "/:unique?" # query action(search)
	.get (req, res, next)->
		if req.query.search? or req.params.unique?
			res.locals.search = if req.params.unique? then req.params.unique else req.query.search
			err, posts <- async.parallel [
				(done)->
					# search date
					if res.locals.search.split("...").length is 2
						date0 = new Date(res.locals.search.split("...").0)
						date1 = new Date(res.locals.search.split("...").1)
						if moment(date0).isValid! and moment(date1).isValid!
							err, posts <- Post.find {
								"course":ObjectId(res.locals.course._id)
								"type":"blog"
								# "title":res.locals.search
								"timestamp":{
									$gte: date0
									$lt: date1
								}
							}
							.populate "author"
							.lean!
							.exec
							done err, posts
						else
							done! # it's not a date range
					else
						done! # it's not a range
				(done)->
					# search text
					err, posts <- Post.find {
						"course": ObjectId res.locals.course._id
						"type": "blog"
						"text": new RegExp res.locals.search, "i"
					}
					.populate "author"
					.lean!
					.exec
					done err, posts
				(done)->
					# search titles
					err, posts <- Post.find {
						"course": ObjectId res.locals.course._id
						"type": "blog"
						"title": new RegExp encodeURIComponent(res.locals.search), "i"
					}
					.populate "author"
					.lean!
					.exec
					done err, posts
				(done)->
					# search tags
					err, posts <- Post.find {
						"course": ObjectId res.locals.course._id
						"type": "blog"
						"tags": res.locals.search
					}
					.populate "author"
					.lean!
					.exec
					done err, posts
				(done)->
					# search authorName
					err, posts <- Post.find {
						"course": ObjectId res.locals.course._id
						"type": "blog"
						"authorName": new RegExp res.locals.search, "i"
					}
					.populate "author"
					.lean!
					.exec
					done err, posts
			]
			posts = _.flatten _.without(posts,undefined), true
			posts = if posts.length > 0 then _.uniq _.sortBy(posts, "timestamp").reverse!
			res.render "course/blog/default", { success: req.query.success, action: req.query.verb, blog: posts, csrf: req.csrfToken! }
		else
			err, posts <- Post.find {
				"course": ObjectId res.locals.course._id
				"type":"blog"
			} .populate("author").exec
			res.locals.blog = _.sortBy posts, "timestamp" .reverse!
			res.render "course/blog/default", { success: req.query.success, action: req.query.verb, csrf: req.csrfToken! }

module.exports = router
