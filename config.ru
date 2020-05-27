# config.ru
require 'rack'
require './app'

run Sinatra::Application
