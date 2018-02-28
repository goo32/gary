#!/usr/bin/env ruby

require 'rack'
require_relative 'web_framework'

router = App.new do
  get '/' do
    'the root'
  end

  get '/user/:username' do |params|
    "the user is #{params.fetch('username')}"
  end
end

Rack::Handler::WEBrick.run router
