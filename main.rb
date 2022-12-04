# frozen_string_literal: true

require 'erb'
require 'sinatra'

set :port, 9876

def accepts(request)
  request.accept
         .map(&:entry)
         .map { |x| before(x, ';') }
         .sort
end

def before(value, test)
  pos1 = value.index(test)
  return value if pos1.nil?

  value[0, pos1]
end

def dump_array(value)
  value.map { |k, v| "\n  #{k}=#{v}" }.join(' ')
end

def dump_list(value)
  value.map { |k| "\n  #{k}" }.join(' ')
end

def dump(request, method, accept)
  content_type (accept == 'json' ? 'application/json' : 'text/plain')
  <<~HEREDOC
    HTTP_USER_AGENT=#{request.env['HTTP_USER_AGENT']}
    Method: #{method}
    request.accept:#{dump_list accepts(request)}

    request.url=#{request.url}
    request.fullpath=#{request.fullpath}
    request.path_info=#{request.path_info}

    request.params:#{dump_array request.params}

    Computed Content-Type: #{accept}
  HEREDOC
end

get '/' do
  content_type 'html'
  erb :index
end

get '/dump/?' do
  dump request, 'GET', 'plain'
end

post '/dump/?' do
  accepts(request).each do |type|
    case type.to_s
    when '*/*', 'text/html'
      return dump request, 'POST', 'plain'
    when 'application/json'
      return dump request, 'POST', 'json'
    end
  end
  error 406
end
