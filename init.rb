require 'rubygems'
require 'sinatra'

require 'yaml'
require 'lib/pickr'

get '/?' do
	Pickr::Gallery.get(Pickr::USER_ID).to_html("test")
end

get '/:id' do
	Pickr::PhotoSet.get(params[id]).to_html($config['set_photo_size'])
end
