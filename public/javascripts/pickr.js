var Pickr = {
	selected: [],
}

$(document).ready(function(){
	$('#selector #close-button').click(hideSelector);

	$('input[name=photo]').change(function(){
		alert("changed");
		if ( $(this).attr('checked') == true ) { selectPhoto($(this).val()) }
		else                                   { deSelectPhoto($(this).val()) }
	});
});

// Array Remove - By John Resig (MIT Licensed)
Array.prototype.remove = function(from, to) {
  var rest = this.slice((to || from) + 1 || this.length);
  this.length = from < 0 ? this.length + from : from;
  return this.push.apply(this, rest);
};

function toogleCheckBox($box) {
	if ( $box.attr('checked') == true ) {
		$box.attr('checked', false);
		deSelectPhoto($box.val());
	}
	else { 
		$box.attr('checked', true);
		selectPhoto($box.val());
	}
	return false;
}

function selectPhoto(id) {
	Pickr.selected.push(id);

	$.get('/thumbnail/' + id, function(data) {
			$("#selected_photos").append(data);
	});
	if ($("#selector").css('display') == 'none') {
		showSelector();
	}
	$('#photo_' + id).animate({ opacity : 0.3 });
}

function deSelectPhoto(id) {
	var i = jQuery.inArray(id, Pickr.selected)
	if ( i != -1 ) Pickr.selected.remove(i); // it's in there

	if ( Pickr.selected.length == 0 ) hideSelector();

	$('#photo_' + id).animate({ opacity : 1 });

	// remove thumb from selector
	$("#selector-thumb-" + id).remove();

	// uncheck checkbox
	$box = $("#select_" + id);
	if ( $box.attr('checked') == true ) $box.attr('checked', false);
}

function showSelector() {
	$("#selector").slideDown();
}

function hideSelector() {
	$('#selector').slideUp();
}
