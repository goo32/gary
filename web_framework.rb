#!/usr/bin/env ruby

class App
  def initialize(&block)
    @routes = RouteTable.new(block)
  end

  def call(env)
    request = Rack::Request.new(env)
    @routes.each do |route|
      content = route.match(request)
      return ['200', {'Content-Type' => 'text/html'}, [content]] if content
    end

    not_found
  end

  def not_found
    ['404', {}, ["not found"]]
  end

  class RouteTable
    def initialize(block)
      @routes = []
      instance_eval(&block)
    end

    def get(route_spec, &block)
      @routes << Route.new(route_spec, block)
    end

    def each(&block)
      @routes.each(&block)
    end    
  end

  class Route < Struct.new(:route_spec, :block)
    def match(request)
      path_components = request.path.split('/')
      spec_components = route_spec.split('/')

      params = {}

      return nil unless path_components.length == spec_components.length

      path_components.zip(spec_components).each do |path_comp, spec_comp|
        is_var = spec_comp.start_with?(':')
        if is_var
          key = spec_comp.sub(/\A:/, '')
          params[key] = path_comp
        else
          return nill unless path_comp == spec_comp
        end        
      end
      block.call(params)
    end
    
    # Not recommended method
    def match_route_using_regex(request)
      path = request.path
      re_text = route_spec.gsub(/:\w+/, '(.+)')
      re = /\A#{re_text}\z/
      if re.match?(path)
        env_keys = route_spec.scan(/:(\w+)/).flatten(1)
        env_values = re.match(path).captures
        block.call env_keys.zip(env_values).to_h
      else
        nil
      end
    end
  end
end
