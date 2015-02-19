module.exports = (app)->
	require! {
		'async'
	}
	app
		.use (req, res, next)->
			async.parallel [
				->
					next!
				->
					if req.headers['user-agent'].match(/Mobile/i)
						res.locals.mobile = true
				->
					if req.headers['user-agent'].match(/Android/i)
						res.locals.mobile = true
				->
					if req.headers['user-agent'].match(/BlackBerry/i)
						res.locals.mobile = true
				->
					if req.headers['user-agent'].match(/iPhone|iPad|iPod/i)
						res.locals.mobile = true
				->
					if req.headers['user-agent'].match(/Opera Mini/i)
						res.locals.mobile = true
				->
					if req.headers['user-agent'].match(/IEMobile/i)
						res.locals.mobile = true
				->
					if req.headers['user-agent'].match(/Silk/i)
						res.locals.mobile = true
				->
					if req.headers['user-agent'].match(/SymbianOS/i)
						res.locals.mobile = true
			]
