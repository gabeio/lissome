module.exports = (app)->
	require('./auth')(app)			# authy checking middleware
	require('./login')(app)			# login
	require('./logout')(app)		# logout
	require('./dashboard')(app) 	# user dashboard
	require('./course')(app) 		# course index/edit
	require('./assignments')(app) 	# hw/projects/other
	require('./examinations')(app) 	# exams/tests/quizes/etc
	require('./conference')(app) 	# community chat/forum(single level/maybe 2 level)
	require('./dm')(app) 			# direct to teacher/student
	require('./blog')(app) 			# updates/rants/etc
	require('./error')(app) 		# after all catch errors
