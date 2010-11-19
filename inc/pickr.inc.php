<?php
require_once(dirname(__FILE__) . "/phpFlickr/phpFlickr.php");
require_once(dirname(__FILE__) . "/config.inc.php");

define("API_KEY", $config['flickr_api_key']);
define("USER_ID", $config['user_id']);
define("FLICKR_PHOTO_URL", "http://www.flickr.com/photos");
define("FLICKR_STATIC_URL", "http://farm5.static.flickr.com");
define("PRIMARY_PHOTO_CACHE", $config['primary_photo_cache']);

class PhotoSet {
	private $id;
	private $title;
	private $photos;
	private $primaryPhoto;
	private $primaryPhotoId;

	function __construct($id, $title, $description, $primaryPhotoId, $photos=array()) {
		$this->id             = $id;
		$this->title          = $title;
		$this->description    = $description;
		$this->photos         = $this->constructPhotos($photos);
		$this->primaryPhotoId = $primaryPhotoId;
	}

	private function constructPhotos($photos) {
		if (count($photos) < 1) return array();
		$objPhotos = array();
		foreach ($photos as $photo) {
			array_push($objPhotos, new Photo(
				$photo['id'],
				$photo['title'],
				$photo['server'],
				$photo['secret']
			));
		}
		return $objPhotos;
	}

	public function getPrimaryPhotoURL() {
		$fh   = fopen(PRIMARY_PHOTO_CACHE, 'r');
		while ( $row = fgetcsv($fh) ) {
			if ( $row[0] == $this->id ) return $row[1];
		}
		fclose($fh);
		return ""; // return a default icon
	}

	static function get($id) {
		$f    = new phpFlickr(API_KEY, null, true);
		$set  = $f->photosets_getPhotos($id);
		$info = $f->photosets_getInfo($id);
		return new PhotoSet(
				$id, 
				$info['title'], 
				$info['description'], 
				$set['photoset']['primary'],
				$set['photoset']['photo']);
	}
	
	function getId()             { return $this->id; }

	function getTitle()          { return $this->title; }
	function setTitle($title)    { $this->title = $title; }

	function getPhotos()         { return $this->photos; }

	function getPrimaryPhotoId() { return $this->primaryPhotoId; }

	function getPrimaryPhoto() {
		return Photo::get($this->primaryPhotoId);
	}

	function getPhotosAsHTML($imgSize) {
		$html = '';
		foreach ($this->photos as $photo) {
			$html .= $photo->toHTML($imgSize);
		}
		return $html;
	}

	function toIndexListing() {
		$icon = $this->getPrimaryPhotoURL();
		return <<<HTML
<div id="set_$this->id">
	<a href="?id=$this->id"><img src="$icon" width="75" height="75" /></a>
	<a href="?id=$this->id">$this->title</a>
</div>
HTML;
	}

	function toHTML($imgSize='thumb') {
		$photoList  = $this->getPhotosAsHTML($imgSize);
		return <<<HTML
<h2>$this->title</h2>
<p class="description">$this->description</p>
<div class="photo-list">
$photoList
</div>
HTML;
	}
}

/*
 *  Inherits from PhotoSet
 */ 	
class Event {

}

class Photo {
	private $id;
	private $title;
	private $server;
	private $secret;

	function __construct($id, $title, $server, $secret) {
		$this->id     = $id;
		$this->title  = $title != '' ? $title : "Untitled";
		$this->server = $server;
		$this->secret = $secret;
	}

	static function get($id) {
		$f    = new phpFlickr(API_KEY, null, true);
		$photo  = $f->photos_getInfo($id);
		//print_r($photo);
		return new Photo(
				$id, 
				$photo['title'], 
				$photo['server'], 
				$photo['secret']);
	}

	function getId()    { return $this->id; }
	function setId($id) { $this->id = $id; }

	function getTitle() { return $this->title; }

	function getServer()        { return $this->server; }
	function setServer($server) { $this->server = $server; }

	function getSecret()        { return $this->secret; }
	function setSecret($secret) { $this->secret = $secret; }

	function toURL() {
		return $this->toMediumURL();
	}

	private function toBaseURL() {
		return FLICKR_STATIC_URL . "/" . $this->getServer() .
			"/" . $this->getId() . "_" . $this->getSecret();
	}

	function toSquareURL() {
		return $this->toBaseURL() . "_s.jpg";
	}

	function toThumbnailURL() {
		return $this->toBaseURL() . "_t.jpg";
	}

	function toOriginalURL() {
		return $this->toBaseURL() . ".jpg";
	}

	function toMediumURL() {
		return $this->toBaseURL() . "_m.jpg";
	}

	// TODO: find away to detagle this method from USER_ID
	function toPageURL() {
		return FLICKR_PHOTO_URL . "/" . USER_ID . "/" . $this->id;
	}

	function toHTML($imgSize='thumb') {
		switch ($imgSize) {
			case 'square':
				$imgURL = $this->toSquareURL();
				break;
			case 'thumb':
				$imgURL = $this->toThumbnailURL();
				break;
			case 'medium':
				$imgURL = $this->toMediumURL();
				break;
			case 'original':
				$imgURL = $this->toOriginalURL();
				break;
			default:
				$imgURL = $this->toThumbnailURL();	
		}
		$pageURL  = $this->toPageURL();
		return <<<HTML
<div class="photo-region">
	<a href="$pageURL" target="__page-$this->id">
		<img class="photo" id="photo_$this->id" src="$imgURL" title="$this->title" />
	</a><br />
	<input type="checkbox" name="photo" value="$this->id" />
	<label for="photo_$this->id">Select</label>
</div>
HTML;
	}

}

class Gallery {
	private $userId;
	private $sets;

	function __construct($userId, $sets) {
		$this->userId = $userId;
		$this->sets   = $this->constructSets($sets);
	}

	private function constructSets($sets) {
		if (count($sets) < 1) return array();
		$objSets = array();
		foreach ($sets as $set) {
			array_push($objSets, new PhotoSet(
				$set['id'],
				$set['title'],
				$set['description'],
				$set['primary']
			));
		}
		return $objSets;
	}

	static function get($userId) {
		$f    = new phpFlickr(API_KEY, null, true);
		$sets = $f->photosets_getList($userId);
		//print_r($sets);
		return new Gallery($userId, $sets['photoset']);
	}

	function getUserID() { return $this->userId; }

	function getSets()   { return $this->sets; }

	private function getSetsAsHTML() {
		$html = '';
		foreach ($this->sets as $set) {
			$html .= $set->toIndexListing();
		}
		return $html;
	}

	function toHTML($title='Events') {
		$setList = $this->getSetsAsHTML();
		return <<<HTML
<h1>$title</h1>
<div id="set-list">
$setList
</div>
HTML;
	}

	static function showSet($setId, $imgSize='medium') {
		return PhotoSet::get($setId)->toHTML($imgSize);
	}
}

class Paginator {
	private $perPage;
	private $pageCount;
	private $recordsCount;
	private $pages;

	function __construct($records, $perPage=10) {
		$this->perPage     = $perPage;
		$this->pages       = array_partition($records, $perPage);
		$this->recordCount = count($records);
		$this->pageCount   = count($this->pages);
	}

	function getPerPage()     { return $this->perPage; }

	function getPageCount()   { return $this->pageCount; }

	function getRecordCount() { return $this->recordsCount; }

	function getPages()       { return $this->pages; }

	function getPage($page) {
			if ( $page <= 0 || $page > count($this->pages) )
				return null; 
			else
				return $this->pages[$page-1]; 
	}

	function toHTML($selected) {
		$html = '<div id="paginator">';
		for ($i = 1; $i <= $this->pageCount; $i++) {
			$html .= '<span>';
			if ( $i == $selected ) $html .= $i;
			else                   $html .= "<a href=\"#$i\">$i</a>";
			$html .= '</span>';
		}
		$html .= '</div>';
		return $html;
	}
}


function array_partition($array, $size=5) {
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

