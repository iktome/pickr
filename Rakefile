JRUBY_BIN = "/home/delon/.rvm/gems/jruby-1.5.6/bin"

desc "Deploy to Google Appengine"
task :deploy do
	sh "#{JRUBY_BIN}/appcfg.rb update ."
end

desc "Run development server"
task :server do
	sh "#{JRUBY_BIN}/dev_appserver.rb ."
end
