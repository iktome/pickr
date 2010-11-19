<?php
require_once(dirname(__FILE__) . '/inc/pickr.inc.php');
require_once(dirname(__FILE__) . '/inc/config.inc.php');

header('Content-type: text/plain');

$sets = Gallery::get($config['user_id'])->getSets();
if ( count($sets) > 0 ) {
	$fh = fopen($config['primary_photo_cache'], 'w');
	foreach ( $sets as $set ) {
		echo $set->getId() . "\n";
		fputcsv($fh, array($set->getId(),
					$set->getPrimaryPhoto()->toSquareURL()));
	}
	echo "done.\n";
	fclose($fh);
}
else {
	echo "no sets found.\n";
}

