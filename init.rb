require 'rubygems'
require 'sinatra'

require 'lib/pickr'


get '/?' do
	Pickr::Gallery.get(Pickr::USER_ID).to_html(Pickr::GALLERY_TITLE)
end

get '/:id' do
	Pickr::PhotoSet.get(params[:id]).to_html(Pickr::SET_PHOTO_SIZE)
end
