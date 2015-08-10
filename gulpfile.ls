require! {
	"del"
	"gulp"
	"gulp-livescript"
	"winston"
}
livescript = if gulp-livescript? then gulp-livescript

paths =
	scripts: [
		"./src/*.ls"
		"./src/databases/*.ls"
		"./src/course/*.ls"
		"./src/preferences/*.ls"
		"./src/frontend/*.ls"
		"./src/commandline/*.ls"
		"./*.json.ls"
	]

gulp.task "default" ["build"] (done)->
	done!

gulp.task "clean" (done)->
	del "./lib/*.js"
	done!

gulp.task "build-gulp" ->
	gulp.src "./gulpfile.ls"
		.pipe livescript bare:true
		.on "error" -> winston.error it
		.pipe gulp.dest "./"

gulp.task "build" ->
	gulp
		..src "./src/*.ls"
		.pipe livescript bare:true
		.on "error" -> winston.error it
		.pipe gulp.dest "./lib/"

		..src "./src/databases/*.ls"
		.pipe livescript bare:true
		.on "error" -> winston.error it
		.pipe gulp.dest "./lib/databases/"

		..src "./src/course/*.ls"
		.pipe livescript bare:true
		.on "error" -> winston.error it
		.pipe gulp.dest "./lib/course/"

		..src "./src/preferences/*.ls"
		.pipe livescript bare:true
		.on "error" -> winston.error it
		.pipe gulp.dest "./lib/preferences/"

		..src "./src/frontend/*.ls"
		.pipe livescript bare:true
		.on "error" -> winston.error it
		.pipe gulp.dest "./public/assets/custom/"

		..src "./src/commandline/*.ls"
		.pipe livescript bare:true
		.on "error" -> winston.error it
		.pipe gulp.dest "./lib/commandline/"

		..src "./*.json.ls"
		.pipe livescript!
		.on "error" -> winston.error it
		.pipe gulp.dest "./"

gulp.task "clean-tests" (done)->
	del "./test/*.js"
	done!

gulp.task "build-tests" ["clean-tests"] ->
	gulp.src "./test/*.ls"
		.pipe livescript bare:true
		.on "error" -> winston.error it
		.pipe gulp.dest "./test/"

gulp.task "watch-build" ->
	gulp
		..watch paths.scripts, ["build"]
