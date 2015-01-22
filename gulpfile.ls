require! {
	'del'
	'gulp'
	'gulp-mocha'
	'gulp-uglify'
	'gulp-istanbul'
	'gulp-livescript'
}
fs = if fsExtra? then fsExtra
mocha = if gulpMocha? then gulpMocha
git = if gulp-git? then gulp-git
concat = if gulp-concat? then gulp-concat
livescript = if gulp-livescript? then gulp-livescript
uglify = if gulp-uglify? then gulp-uglify
istanbul = if gulp-istanbul? then gulp-istanbul

paths =
	scripts: './*.ls'
	tests: './test/*.ls'

gulp.task 'clean' (done)->
	# del './db'
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

gulp.task 'cover' ['build-tests','clean','build'] (done)->
	gulp
		.src ['./app.js','./base.js','./editable.js','./admin.js']
		.pipe istanbul!
		.pipe istanbul.hookRequire!
		.on 'finish' ->
			gulp
				.src './test/*.js'
				.pipe mocha!
				.pipe istanbul.writeReports!
				.on 'finish' done

gulp.task 'watch-build' ->
	gulp
		..watch paths.scripts, ['build']

gulp.task 'watch-tests' ->
	gulp
		..watch paths.tests, ['test']
