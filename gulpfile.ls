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

gulp.task "build" ->
	gulp
		..src "./src/**/*.ls"
		.pipe livescript bare:true
		.on "error" -> winston.error it
		.pipe gulp.dest "./lib/"
		..src "./src/frontend/**/*.ls"
		.pipe livescript bare:true
		.on "error" -> winston.error it
		.pipe gulp.dest "./public/assets/custom/"
		..src "./*.json.ls"
		.pipe livescript!
		.on "error" -> winston.error it
		.pipe gulp.dest "./"

gulp.task "build-tests" ->
	gulp.src "./test/**/*.ls"
		.pipe livescript bare:true
		.on "error" -> winston.error it
		.pipe gulp.dest "./test/"

gulp.task "watch-build" ->
	gulp
		..watch paths.scripts, ["build"]
