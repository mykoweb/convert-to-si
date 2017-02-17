ENV['SINATRA_ENV'] = 'test'
require 'rack/test'
require File.expand_path '../../app.rb', __FILE__
require File.expand_path '../../converter.rb', __FILE__
require File.expand_path '../../errors.rb', __FILE__

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.order = :random
end

def app
  Rack::Builder.parse_file('config.ru').first
end
