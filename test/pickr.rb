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

	def test_photo_to_html
		doc = Nokogiri::HTML(@photo.to_html)
		p doc.css('div a[href]')
	end

end

class TestPhotoSet < Test::Unit::TestCase
	
	def setup
		@set = Pickr::PhotoSet.get('72157624264693371')
	end

	def test_get_photoset_type
		p @set
		assert_instance_of Pickr::PhotoSet, @set, "result should be an instace of Pickr::PhotoSet"
	end
end
