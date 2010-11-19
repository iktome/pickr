<?php

require_once(dirname(__FILE__) . "/inc/pickr.inc.php");
require_once(dirname(__FILE__) . "/inc/config.inc.php");

$id = $_GET['id'];
if ( $id ) {
	echo PhotoSet::get($id)->toHTML($config['set_photo_size']);
}
else {
	echo Gallery::get($config['user_id'])->toHTML($config['gallery_title']);
}
