require "habitat"
require "http/client"
require "json"

BASE_URL   = "https://hub.docker.com/v2"
LOGIN_PATH = "/users/login/"

class InvalidCredentials < Exception
end

class UnknownResponse < Exception
end

class Prune
  @@token : String?

  Habitat.create do
    setting password : String
    setting user : String
    setting repository : String
    setting keep : Int32
    setting dry : Bool = false
  end

  def initialize
  end

  @@client = HTTP::Client.new URI.parse(BASE_URL)

  @@client.before_request do |request|
    puts request.path
    if request.path != LOGIN_PATH
      @@token ||= authenticate
      request.headers["Authorization"] = "JWT #{@@token}"
    end
    request.headers["Content-Type"] = "application/json"
  end

  private def self.authenticate
    payload = JSON.build do |json|
      json.object do
        json.field "username", settings.user
        json.field "password", settings.password
      end
    end

    @@client.post LOGIN_PATH, body: payload do |response|
      puts response.body_io.gets_to_end
      raise InvalidCredentials.new if response.status_code != 200
      JSON.parse(response.body_io)["token"].as_s
    end
  end

  private def tags
    @@client.get "/repositories/#{settings.user}/#{settings.repository}/tags/" do |response|
      puts response.body_io.gets_to_end
    end
  end

  def run
    tags
  rescue InvalidCredentials
    puts "Unable to login with the provided credentials"
  rescue UnknownResponse
    puts "Server returned a response that can't be handled"
  end
end
