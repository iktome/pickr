require 'rubygems'
require 'flickraw-cached'
require 'fastercsv'
require 'yaml'
require 'json'

module Pickr
	$config = YAML.load_file(File.join(File.expand_path(File.dirname(__FILE__)), '../config.yml'))

	FLICKR_PHOTO_URL    = "http://www.flickr.com/photos".freeze
	FLICKR_STATIC_URL   = "http://farm5.static.flickr.com".freeze

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

		def initialize(id, title, description, primary_photo_id, photos=[])
			@id               = id
			@title            = title
			@description      = description
			@photos           = construct_photos(photos)
			@primary_photo_id = primary_photo_id
		end
	
		private
		
		def construct_photos(photos)
			photos.map do |photo| 
				Photo.new(photo.id, photo.title, photo.server, photo.secret)
			end
		end

		public
	
		def primary_photo_url
			begin
				cache = JSON.parse(IO.read(PRIMARY_PHOTO_CACHE))
				cache.keys.sort.each do |cache_id|
					return cache[id] if cache_id == @id
				end
			rescue
				"" # TODO: return a default icon
			end
		end
	
		def self.get(id)
			set  = flickr.photosets.getPhotos :photoset_id => id
			info = flickr.photosets.getInfo   :photoset_id => id

			PhotoSet.new(id, info.title,  info.description,
						           set.primary, set.photo)
		end
		
		def primary_photo
			@primary_photo ||= Photo.get(@primary_photo_id);
		end
	
		def photos_as_html(img_size)
			photos.map { |photo| photo.to_html(img_size) }.join("")
		end
	
		def to_index_listing
			return <<-HTML
				<div id="set_#{@id}">
					<a href="/#{@id}"><img src="#{primary_photo_url}" width="75" height="75" /></a>
					<a href="/#{@id}">#{@title}</a>
				</div>
			HTML
		end
	
		def to_html(img_size='thumb')
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
	
		def self.get(id)
			photo = flickr.photos.getInfo :photo_id => id

			Photo.new(id, photo.title, photo.server, photo.secret)
		end
	
		def to_url
			to_medium_url # defaults to medium
		end
	
		private

		def to_base_url
			"#{FLICKR_STATIC_URL}/#{server}/#{id}_#{secret}"
		end

		public
	
		def to_square_url
			"#{to_base_url}_s.jpg"
		end
	
		def to_thumbnail_url
			"#{to_base_url}_t.jpg"
		end
	
		def to_original_url
			"#{to_base_url}.jpg"
		end
	
		def to_medium_url
			"#{to_base_url}_m.jpg"
		end
	
		# TODO: find away to detagle this method from USER_ID
		def to_page_url
			"#{FLICKR_PHOTO_URL}/#{USER_ID}/#{id}"
		end
	
		def to_html(img_size='thumb')
			case img_size
			when 'square'
				img_url = to_square_url
			when 'thumb'
				img_url = to_thumbnail_url
			when 'medium'
				img_url = to_medium_url
			when 'original'
				img_url = to_original_url
			else
				img_url = to_thumbnail_url	
			end
			page_url  = to_page_url
			return <<-HTML
				<div class="photo-region">
					<a href="#{page_url}" target="__page-#{id}">
						<img class="photo" id="photo_#{id}" src="#{img_url}" title="#{title}" />
					</a><br />
					<input type="checkbox" name="photo" value="#{id}" />
					<label for="photo_#{id}">Select</label>
				</div>
			HTML
		end
	
	end
	
	class Gallery
		attr_reader :user_id, :sets
	
		def initialize(user_id, sets)
			@user_id = user_id;
			@sets    = construct_sets(sets);
		end
	
		private 

		def construct_sets(sets)
			return [] if sets.count < 1
			sets.map do |set|
				PhotoSet.new(set.id, set.title, set.description, set.primary)
			end
		end
	
		def get_sets_as_html
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
					#{get_sets_as_html}
				</div>
			HTML
		end
	
		def self.show_set(set_id, img_size='medium')
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
	end
	
end
