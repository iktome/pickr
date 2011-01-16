require 'lib/pickr'
require 'test/unit'

require 'rubygems'
require 'nokogiri'

class TestPhoto < Test::Unit::TestCase
	def setup
		@photo = Pickr::Photo.get('5210606401')
	end

	def test_get_photo_type
		assert_instance_of Pickr::Photo, @photo, "result should be an instace of photo"
	end

	def test_page_url
		assert_equal "http://www.flickr.com/photos/26835295@N06/5210606401", @photo.url(:page)
	end

	def test_lightbox_url
		assert_equal "http://www.flickr.com/photos/26835295@N06/5210606401/lightbox", @photo.url(:lightbox)
	end
end

class TestPhotoSet < Test::Unit::TestCase
	
	def setup
		@set = Pickr::PhotoSet.get('72157624264693371')
	end

	def test_get_photoset_type
		assert_instance_of Pickr::PhotoSet, @set, "result should be an instace of Pickr::PhotoSet"
	end

	def test_primary_photo_default_photo
		photo = @set.primary_photo # starts thread to fetch image and returns a default image
		assert photo.respond_to?(:url), "default photo class is derived but has a 'url' method"
	end
end
