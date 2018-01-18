var jshint = require('gulp-jshint');
var gulp = require('gulp');

gulp.task('lint', function() {
  gulp.src(['./app/assets/javascripts/modules/**/*.js', './app/assets/javascripts/*.js'])
    .pipe(jshint())
    .pipe(jshint.reporter('default'));
});


var sass = require('gulp-sass');
var notify = require('gulp-notify');
var livereload = require('gulp-livereload');
var lr = require('tiny-lr');
var server = lr();

gulp.task('styles', function(){
	return gulp.src('app/assets/stylesheets/webview/main.scss')
		.pipe(sass({ outputStyle: 'expanded', errLogToConsole: true, onError: function(err){
			notify({message:err});
		}}))
		.pipe(gulp.dest('app/assets/stylesheets/webview'))
		.pipe(livereload(server))
		.pipe(notify({message: 'SCSS compiled!'}));
});

gulp.task('watch', function(){
	server.listen(35729, function(err){
		if(err){
			notify({message:err});
		};
	});

	gulp.watch('app/assets/stylesheets/webview/**/*.scss', ['styles']);
});