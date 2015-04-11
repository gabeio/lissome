require! {
	"express"
}
app = express.Router()
require! {
	"async"
	"lodash"
	"moment"
	"mongoose"
	"uuid"
	"winston"
}
_ = lodash
ObjectId = mongoose.Types.ObjectId
User = mongoose.models.User
Course = mongoose.models.Course
Post = mongoose.models.Post

app
	..route "/:unique?" # query action(new|edit|delete|deleteall)
	.all (req, res, next)->
		console.log 'blog.ls req.params', req.params
		if req.query.action in ["new","edit","delete","deleteall"]
			next!
		else
			next "route"
	.all (req, res, next)->
		res.locals.needs = 2
		next!
	.all (req, res, next)->
		if res.locals.auth? and res.locals.needs? and res.locals.needs <= res.locals.auth
			next!
		else
			next new Error "UNAUTHORIZED"
	.get (req, res, next)->
		if req.query.action in ["edit","delete"]
			if !req.params.unique?
				res.redirect "/#{res.locals.course.id}/blog"
			else
				err, result <- Post.find {
					"course": ObjectId res.locals.course._id
					"type": "blog"
					"title": req.params.unique
				} .populate "author" .exec
				if result.length is 0
					res.redirect "/#{res.locals.course.id}/blog"
				else
					/* istanbul ignore next else because it's hard to test for */
					res.locals.posts = if result.length isnt 0 then _.sortBy result, "timestamp" .reverse! else []
					next!
		else
			next!
	.get (req, res, next)->
		switch req.query.action
		| "new"
			res.render "blog/create", { on:"newblog", success:req.query.success, action:"created" }
		| "edit"
			res.render "blog/edit", { on:"editblog", success:req.query.success, action:"updated" }
		| "delete"
			res.render "blog/del", { on:"deleteblog", success:req.query.success, action:"deleted" }
	.post (req, res, next)->
		/* istanbul ignore else */
		if req.query.action is "new"
			async.parallel [
				->
					if req.body.text? and req.body.text isnt "" and req.body.title? and req.body.title isnt ""
						res.render "blog/create", { "blog":true, "on":"newblog", success:"yes", action:"created" } # return
					else
						res.status 400 .render "blog/create", { "blog":true, "on":"newblog", success:"no", action:"created", body: req.body }
				->
					if req.body.text? and req.body.text isnt "" and req.body.title? and req.body.title isnt ""
						post = new Post {
							# uuid: res.locals.postuuid
							title: encodeURIComponent req.body.title
							text: req.body.text
							# files: req.body.files
							author: ObjectId res.locals.uid
							authorName: res.locals.firstName+" "+res.locals.lastName
							authorUsername: res.locals.username
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
	.put (req, res, next)->
		if req.query.action is "edit"
			async.parallel [
				->
					if req.body.text? and req.body.text isnt "" and req.body.title? and req.body.title isnt ""
						res.redirect "/#{res.locals.course.id}/blog/#{req.params.unique}?action=edit&success=yes"
					else
						res.status 400 .render "blog/create", { blog:true, on:"editblog", success:"no", action:"updated", body: req.body}
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
	.delete (req, res, next)->
		if req.query.action in ["delete","deleteall"]
			async.parallel [
				->
					res.redirect "/#{res.locals.course.id}/blog?action=delete&success=yes"
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
	.all (req, res, next)->
		res.locals.needs = 1
		next!
	.all (req, res, next)->
		if res.locals.auth? and res.locals.needs? and res.locals.needs <= res.locals.auth
			next!
		else
			next new Error "UNAUTHORIZED"
	.get (req, res, next)->
		# res.locals.blog = []
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
							} .populate "author" .exec
							done err,posts
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
					} .populate("author").exec#, (err, posts)->
					done err, posts
				(done)->
					# search titles
					err, posts <- Post.find {
						"course": ObjectId res.locals.course._id
						"type": "blog"
						"title": new RegExp res.locals.search, "i"
					} .populate("author").exec#, (err, posts)->
					done err, posts
				(done)->
					# search tags
					err, posts <- Post.find {
						"course": ObjectId res.locals.course._id
						"type": "blog"
						"tags": res.locals.search
					} .populate("author").exec#, (err, posts)->
					done err, posts
				(done)->
					# search authorName
					err, posts <- Post.find {
						"course": ObjectId res.locals.course._id
						"type": "blog"
						"authorName": new RegExp res.locals.search, "i"
					} .populate("author").exec#, (err, posts)->
					done err, posts
			]
			posts = _.flatten _.without(posts,undefined), true
			posts = if posts.length > 0 then _.uniq _.sortBy(posts, "timestamp").reverse!,(input)->
				return input.timestamp.toString!
			res.render "blog/default", blog: posts
		else
			err, posts <- Post.find {
				"course": ObjectId res.locals.course._id
				"type":"blog"
			} .populate("author").exec
			res.locals.blog = _.sortBy posts, "timestamp" .reverse!
			res.render "blog/default"

module.exports = app
