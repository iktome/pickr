#!/usr/bin/php
<?php
require_once("inc/pickr.inc.php");
echo Gallery::get("26835295@N06")->toHTML("Flickr Sets");
//Photo::get("4759174043");
/*$rs = array();
for ($i = 1; $i < 115; $i++) array_push($rs, $i);

$p = new Paginator($rs);
echo $p->getPageCount() . " Pages\n";
print_r($p->getPage(2));
echo $p->toHTML(1);*/

/*function partition($array, $size=5) {
	if      ( count($array) == 0 )     return array();
	else if ( count($array) <= $size ) return $array;
	else {
		$n = 0; $m = 0;
		$partitioned     = array();
		$partitioned[$m] = array();
		foreach ($array as $item) {
			array_push($partitioned[$m], $item);
			if ( $n == $size ) {
				$n = 0; $m++;
				$partitioned[$m] = array();
			}
			else $n++;
		}
		return $partitioned;
	}
}

print_r(partition($rs)); */
#$set = PhotoSet::get('72157623431077470');
#print_r($set);

