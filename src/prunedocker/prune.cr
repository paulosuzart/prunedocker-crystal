require "habitat"
require "http/client"
require "json"

BASE_URL = "https://hub.docker.com/v2"


class InvalidCredentials < Exception
end

class Prune
  @@token : String | Nil

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
    puts request
    if request.path != "/users/login"
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
    puts payload
    @@client.post "/users/login", body: payload do |response|
      raise InvalidCredentials.new if response.status_code == 301

      JSON.parse(response.body)["token"].as_s
    end
  end

  private def tags
    @@client.get "/repositories/#{settings.user}/#{settings.repository}/tags/" do |response|
      puts response.body
    end
  end

  def run
    tags
  rescue InvalidCredentials
    puts "Unable to login with the provided credentials"
  end
end
