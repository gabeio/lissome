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

gulp.task "default" ["clean","build"] (done)->
	done!

gulp.task "clean" (done)->
	del "lib/**/*.js"
	del "test/**/*.js"
	done!

gulp.task "build" (done)->
	gulp
		..src "./src/**/*.ls"
		.pipe livescript bare:true
		.on "error" -> winston.error it
		.pipe gulp.dest "./lib/"
		.on "done" ->
			done!
		..src "./*.json.ls"
		.pipe livescript!
		.on "error" -> winston.error it
		.pipe gulp.dest "./"
		.on "done" ->
			done!

gulp.task "build-tests" ["clean-tests"] ->
	gulp.src "./test/*.ls"
		.pipe livescript bare:true
		.on "error" -> winston.error it
		.pipe gulp.dest "./test/"

gulp.task "watch-build" ->
	gulp
		..watch paths.scripts, ["build"]
