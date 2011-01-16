require 'rubygems'
require 'sinatra'
require 'haml'
require 'sinatra/static_assets'

require 'lib/pickr'

get '/thumbnail/:id' do
	@photo = Pickr::Photo.get(params[:id])

	haml :thumbnail, :layout => false
end

post '/complete-selection' do

end

post '/send-request' do
	# record request
	# send email
	""
end

get '/?' do
	@title   = Pickr::GALLERY_TITLE
	@gallery = Pickr::Gallery.get(Pickr::USER_ID)

	haml :gallery
end

get '/:id' do
	@set = Pickr::PhotoSet.get(params[:id])

	haml :set
end

