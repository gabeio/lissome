require! {
	'fs-extra'
	'del'
	'gulp'
	'gulp-mocha'
	'gulp-livescript'
}
fs = if fsExtra? then fsExtra
mocha = if gulpMocha? then gulpMocha
git = if gulp-git? then gulp-git
concat = if gulp-concat? then gulp-concat
livescript = if gulp-livescript? then gulp-livescript

paths =
	scripts: './src/*.ls'
	tests: './test/*.ls'

gulp.task 'clean-db' (done)->
	err <- del './db'
	err <- fs.ensureDir './db'
	done err

gulp.task 'clean' (done)->
	del '*.js'
	done!

gulp.task 'build-cramp' ['clean'] (done)->
	gulp
		.src './src/*.ls'
		.pipe livescript bare:true
		.on 'error' -> throw it
		.pipe uglify!
		.pipe gulp.dest '.'
		.on 'end' ->
			del 'gulpfile.js'
			done!

gulp.task 'build' ['clean'] (done)->
	gulp
		.src './src/*.ls'
		.pipe livescript bare:true
		.on 'error' -> throw it
		.pipe gulp.dest '.'
		.on 'end' ->
			del 'gulpfile.js'
			done

gulp.task 'clean-tests' (done)->
	del './test/*.js'
	done!

gulp.task 'build-tests' ['clean-tests'] (done)->
	gulp
		.src './test/*.ls'
		.pipe livescript bare:true
		.on 'error' -> throw it
		.pipe gulp.dest './test/'
		.on 'end' ->
			done

gulp.task 'test' ['build-tests','clean', 'build'] (done)->
	gulp
		.src './test/*.js'
		.pipe mocha!
		.on 'finish' ->
			del './db'
			done

gulp.task 'watch-build' ->
	gulp
		..watch paths.scripts, ['build']

gulp.task 'watch-tests' ->
	gulp
		..watch paths.tests, ['test']
