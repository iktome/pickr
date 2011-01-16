# = Pickr - A Gallery tool for Photographers
# These classes represent are an abstration away from the Flickr API.
# They provide methods for creating a gallery of photos for selecting
# and submitting to the photographer.
#
#	= Summary
#
#	Pickr::Gallery.get('26835295@N06').to_html

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

	# TODO: move this stuff to lib/pickr/cache.rb
	module Cache
	
		# TODO: add checking to opts
		def read(type, *opts)
			if type == :file
				JSON.parse(IO.read(opts[:from]))
			elsif type == :db
				# return db cache
				DB.read(opts[:from])
			end
		end

		class DB
			def self.read(table)

			end
		end

	end
	
	# TODO: move this stuff to lib/pickr/db.rb 
	module DB
		# use DataMapper
		# Models:
		#  - PhotoSet
		#  - Photo  
	end

	# A pickr photo set
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
			photos.map do |photo| 
				Photo.new(photo.id, photo.title, photo.server, photo.secret)
			end
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
		
		def photos_as_html(img_size)
			photos.map { |photo| photo.to_html(img_size) }.join("")
		end
	
		def to_index_listing
			return <<-HTML
				<div id="set_#{@id}">
					<a href="/#{@id}"><img src="#{primary_photo.url(:square)}" width="75" height="75" /></a>
					<a href="/#{@id}">#{@title}</a>
				</div>
			HTML
		end
	
		def to_html(img_size=SET_PHOTO_SIZE)
			photo_list = photos_as_html(img_size)
			return <<-HTML
				<a href="/">&lt;&lt;Back to Index</a>
				<h2>#{@title}</h2>
				<p class="description">#{@description}</p>
				<div class="photo-list">
					#{photo_list}
				</div>
			HTML
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

		def self.blank
			Photo.new(nil, nil, nil, nil)
		end
	
		def self.get(id)
			photo = flickr.photos.getInfo :photo_id => id
			Photo.new(id, photo.title, photo.server, photo.secret)
		end
	
		# generates url for photo of type:
		# - square
		# - thumbnail
		# - original
		# - medium
		# - page
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

		def to_base_url
			@base_url ||= "#{FLICKR_STATIC_URL}/#{server}/#{id}_#{secret}"
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
			@page_url ||= "#{FLICKR_PHOTO_URL}/#{USER_ID}/#{id}"
		end

		def to_lightbox_url
			@lightbox_url ||= "#{to_page_url}/lightbox"
		end

		public
	
		def to_html(img_size=:thumb)
			return <<-HTML
				<div class="photo-region">
					<a href="#{url(:page)}" target="__page-#{id}">
						<img class="photo" id="photo_#{id}" src="#{url(img_size)}" title="#{title}" />
					</a><br />
					<input type="checkbox" name="photo" value="#{id}" />
					<label for="photo_#{id}">Select</label>
				</div>
			HTML
		end

	end # Photo
	
	class Gallery
		attr_reader :user_id, :sets
	
		def initialize(user_id, sets)
			@user_id = user_id
			@sets    = sets.map {|s| PhotoSet.new(s) }
		end
	
		private 

		def sets_as_html
			@sets.map { |set| set.to_index_listing }.join("")
		end

		public
	
		def self.get(user_id)
			sets = flickr.photosets.getList :user_id => user_id
			self.new(user_id, sets)
		end
	
		def to_html(title='Events')
			return <<-HTML
				<h1>#{title}</h1>
				<div id="set-list">
					#{sets_as_html}
				</div>
			HTML
		end
	
		def self.show_set(set_id, img_size=:medium)
			PhotoSet.get(set_id).to_html(img_size)
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
