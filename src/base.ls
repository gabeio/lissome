module.exports = (app)->
	require('./mongoose')(app)		# mongoose models middleware (should only run once)
	#require('./mobile')(app)		# mobile device checking; might use to force long polling over websocket
	require('./auth')(app)			# authy checking middleware
	require('./login')(app)			# login
	require('./logout')(app)		# logout
	require('./dashboard')(app) 	# user dashboard
	require('./course')(app) 		# course index/edit
	require('./assignments')(app) 	# hw/projects/other
	require('./conference')(app) 	# community chat/forum(single level/maybe 2 level)
	# require('./dm')(app) 			# direct to teacher/student
	require('./blog')(app) 			# updates/rants/etc
	require('./error')(app) 		# after all catch errors
