#!/usr/bin/env ruby

require 'rack'

class Router
  def initialize(&block)
    @routes = {}
    instance_eval(&block)
  end

  def call(env)
    path = env.fetch('PATH_INFO')
    @routes.each do |route_spec, callable|
      if env = match_route(route_spec, path)
        return ['200', 
        {'Content-Type' => 'text/html'}, 
        [callable.call(env)]]
      end
    end

    not_found
  end

  def match_route(route_spec, path)
    re_text = route_spec.gsub(/:\w+/, '(.+)')
    re = /\A#{re_text}\z/
    if re.match?(path)
      env_keys = route_spec.scan(/:(\w+)/).flatten(1)
      env_values = re.match(path).captures
      env_keys.zip(env_values).to_h
    else
      nil
    end
  end

  def get(route_spec, &block)
    @routes[route_spec] = block
  end

  def not_found
    ['404', {}, []]
  end
end

router = Router.new do
  get '/' do
    'the root'
  end

  get '/user/:username' do |params|
    "the user is #{params.fetch('username')}"
  end
end

Rack::Handler::WEBrick.run router
