require! {
	'del'
	'gulp'
	'gulp-livescript'
}
livescript = if gulp-livescript? then gulp-livescript

paths =
	scripts: ['./*.json.ls',
		'./src/*.ls',
		'./src/databases/*.ls',
		'./src/course/*.ls',
		'./src/frontend/*.ls']
	tests: ['./test/*.ls','./src/*.ls']

gulp.task 'default' ['build'] (done)->
	done!

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
		..src './src/databases/*.ls'
		.pipe livescript bare:true
		.on 'error' -> throw it
		.pipe gulp.dest './lib/databases/'
		..src './src/course/*.ls'
		.pipe livescript bare:true
		.on 'error' -> throw it
		.pipe gulp.dest './lib/course/'
		..src './src/frontend/*.ls'
		.pipe livescript bare:true
		.on 'error' -> throw it
		.pipe gulp.dest './public/assets/custom/'
		..src './src/commandline/*.ls'
		.pipe livescript bare:true
		.on 'error' -> throw it
		.pipe gulp.dest './lib/commandline/'
		..src './*.json.ls'
		.pipe livescript!
		.on 'error' -> throw it
		.pipe gulp.dest './'

gulp.task 'clean-tests' (done)->
	del './test/*.js'
	done!

gulp.task 'build-tests' ['clean-tests'] ->
	gulp.src './test/*.ls'
		.pipe livescript bare:true
		.on 'error' -> throw it
		.pipe gulp.dest './test/'

gulp.task 'watch-build' ->
	gulp
		..watch paths.scripts, ['build']
