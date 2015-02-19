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
					if req.headers['user-agent'].match(/Mobile/i) # generic
						res.locals.mobile = true
				->
					if req.headers['user-agent'].match(/Android/i) # Android
						res.locals.mobile = true
				->
					if req.headers['user-agent'].match(/BlackBerry|BB10|RIM Tablet/i) # Blackberry
						res.locals.mobile = true
				->
					if req.headers['user-agent'].match(/iPhone|iPad|iPod/i) # Apple
						res.locals.mobile = true
				->
					if req.headers['user-agent'].match(/Opera Mini/i)
						res.locals.mobile = true
				->
					if req.headers['user-agent'].match(/IEMobile|Windows Phone/i) # windows phones
						res.locals.mobile = true
				->
					if req.headers['user-agent'].match(/Silk|Kindle/i) # amazon kindle
						res.locals.mobile = true
				->
					if req.headers['user-agent'].match(/SymbianOS/i) # nokia
						res.locals.mobile = true
				->
					if req.headers['user-agent'].match(/webOS/i) # hp/palm
						res.locals.mobile = true
			]
