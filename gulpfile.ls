require! {
	'del'
	'gulp'
	'gulp-mocha'
	'gulp-livescript'
	'gulp-coveralls'
}
mocha = if gulp-mocha? then gulp-mocha
livescript = if gulp-livescript? then gulp-livescript

paths =
	scripts: ['./*.json.ls', './src/*.ls', './src/frontend/*.ls']
	tests: ['./test/*.ls','./src/*.ls']

gulp.task 'default' ['build'] (done)->
	done

gulp.task 'clean' (done)->
	del './lib/*.js'
	done!

gulp.task 'build-gulp' ->
	gulp.src './gulpfile.ls'
		.pipe livescript bare:true
		.on 'error' -> throw it
		.pipe gulp.dest './'

gulp.task 'build' ['clean'] ->
	gulp
		..src './src/*.ls'
		.pipe livescript bare:true
		.on 'error' -> throw it
		.pipe gulp.dest './lib/'
		..src './src/frontend/*.ls'
		.pipe livescript bare:true
		.on 'error' -> throw it
		.pipe gulp.dest './public/assets/custom/'
		..src './*.json.ls'
		.pipe livescript!
		.on 'error' -> throw it
		.pipe gulp.dest './'

/*gulp.task 'clean-tests' (done)->
	del './test/*.js'*/

gulp.task 'build-tests' -> # ['clean-tests']
	gulp.src './test/*.ls'
		.pipe livescript bare:true
		.on 'error' -> throw it
		.pipe gulp.dest './test/'
		# .on 'end' ->
		# 	done

gulp.task 'run-tests' ['build', 'build-tests'] ->
	gulp.src './test/*.js'
		.pipe mocha!
		# .on 'error' ->
		# 	throw it
		# .on 'end' ->
		# 	process.exit!
		# .on 'error' ->
		# 	process.exit 1

gulp.task 'watch-run-tests' ['build-tests', 'build'] (done)->
	gulp.src './test/*.js'
		.pipe mocha!
		.on 'end' ->
			done

gulp.task 'report' ->
	gulp.src 'coverage/**/lcov.info'
		.pipe coveralls!

gulp.task 'watch-build' ->
	gulp
		..watch paths.scripts, ['build']

gulp.task 'watch-tests' ->
	gulp
		..watch paths.tests, ['watch-run-tests']
