needs-focus.focus! if needs-focus = document.getElementById "autofocus"
$ "form" .submit ->
	$ this .find "input[type=submit]" .attr "disabled", "disabled"
	$ this .find "button[type=submit]" .attr "disabled", "disabled"
