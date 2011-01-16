#
# = Pickr - A Gallery tool for Photographers
# These classes represent are an abstration away from the Flickr API.
# They provide methods for creating a gallery of photos for selecting
# and submitting to the photographer.
#

require 'rubygems'
require 'flickraw-cached'
require 'yaml'
require 'json'

module Pickr
	$config = YAML.load_file(File.join(File.expand_path(File.dirname(__FILE__)), '../config.yml'))

	FLICKR_PHOTO_URL    = "http://www.flickr.com/photos".freeze
	FLICKR_STATIC_URL   = "http://farm5.static.flickr.com".freeze

	# TODO: make these optionally configurable in a db also
	API_KEY             = $config['flickr_api_key'].freeze
	AUTH_TOKEN          = $config['auth_token'].freeze
	USER_ID             = $config['user_id'].freeze
	PRIMARY_PHOTO_CACHE = $config['primary_photo_cache'].freeze
	GALLERY_TITLE       = $config['gallery_title'].freeze
	SET_PHOTO_SIZE      = $config['set_photo_size'].freeze

	FlickRaw.api_key    = API_KEY		

	class PhotoSet
		attr_reader   :id, :description, :photos, :primary_photo_id	
		attr_accessor :title

		def initialize(set, photos=[])
			@set              = set
			@id               = set.id
			@title            = set.title
			@description      = set.description
			@photos           = construct_photos(photos)
			@primary_photo_id = set.primary
		end
	
		private
		
		def construct_photos(photos)
			photos.map {|p| Photo.new(p.id, p.title, p.server, p.secret) }
		end

		public
	
		def primary_photo
			@primary_photo ||= Photo.new(@set.primary, @set.title, @set.server, @set.secret)
		end
	
		def self.get(id)
			set  = flickr.photosets.getPhotos :photoset_id => id
			info = flickr.photosets.getInfo   :photoset_id => id

			PhotoSet.new(info, set.photo)
		end
		
		def url
			"#{FLICKR_PHOTO_URL}/#{USER_ID}/sets/#{@id}"
		end
	
		def to_hash
			{ id => primary_photo.to_square_url }
		end
	end
	
	class Photo
		attr_reader   :title
		attr_accessor :id, :secret, :server
	
		def initialize(id, title, server, secret)
			@id     = id
			@title  = title != '' ? title : "Untitled"
			@server = server
			@secret = secret
		end

		def self.get(id)
			photo = flickr.photos.getInfo :photo_id => id
			Photo.new(id, photo.title, photo.server, photo.secret)
		end
	
		# 
		# Generates url for photo of type:
		# - square
		# - thumbnail
		# - original
		# - medium
		# - page
		# - lightbox
		# 
		def url(type=SET_PHOTO_SIZE)
			return @url unless @url.nil? # allows us to override url generation
			case type
			when :square,    'square'    then to_square_url	
			when :thumbnail, 'thumbnail' then to_thumbnail_url
			when :original,  'original'  then to_original_url
			when :medium,    'medium'    then to_medium_url
			when :page,      'page'      then to_page_url
			when :lightbox,  'lightbox'  then to_lightbox_url
			else to_medium_url # defaults to medium
			end
		end

		def url=(value)
			@url = value
		end
	
		private

		# XXX: It seems there might be a more rubyish way of doing this
		def to_base_url
			@base_url ||= "#{FLICKR_STATIC_URL}/#{@server}/#{@id}_#{@secret}"
		end

		def to_square_url
			@square_url ||= "#{to_base_url}_s.jpg"
		end
	
		def to_thumbnail_url
			@thumbnail_url ||= "#{to_base_url}_t.jpg"
		end
	
		def to_original_url
			@original_url ||= "#{to_base_url}.jpg"
		end
	
		def to_medium_url
			@medium_url ||= "#{to_base_url}_m.jpg"
		end
	
		def to_page_url
			@page_url ||= "#{FLICKR_PHOTO_URL}/#{USER_ID}/#{@id}"
		end

		def to_lightbox_url
			@lightbox_url ||= "#{to_page_url}/lightbox"
		end

	end # Photo
	
	class Gallery
		attr_reader :user_id, :sets
	
		def initialize(user_id, sets)
			@user_id = user_id
			@sets    = sets.map {|s| PhotoSet.new(s) }
		end
	
		def self.get(user_id)
			sets = flickr.photosets.getList :user_id => user_id
			self.new(user_id, sets)
		end
	
		def to_hash(&block)
			h = {}
			sets.each do |s|
				block.call(s)
				h[s.id] = s.primary_photo.to_square_url
			end
			h
		end

		def to_json(&block)
			to_hash(&block).to_json
		end

	end # Gallery
	
end # Pickr
