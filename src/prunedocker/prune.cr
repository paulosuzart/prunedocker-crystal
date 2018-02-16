require "habitat"
require "http/client"
require "json"

BASE_URL   = "https://hub.docker.com"
LOGIN_PATH = "/v2/users/login/"

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
    puts "**RUNNING IN DRY RUN MODE - NOT TAGS WILL BE DELETED**" if settings.dry
  end

  @@client = HTTP::Client.new URI.parse(BASE_URL)

  @@client.before_request do |request|
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
      raise InvalidCredentials.new if response.status_code != 200
      JSON.parse(response.body_io)["token"].as_s
    end
  end

  # Simply fetches tags yielding on each page
  private def fetch_tags
    path = "/v2/repositories/#{settings.user}/#{settings.repository}/tags/"
    loop do
      response = @@client.get path
      tags_payload = JSON.parse(response.body)

      yield tags_payload["results"]

      path = tags_payload["next"].as_s?
      break unless path
    end
  end

  private def delete(tags_to_delete)
    tags_to_delete.each do |tag|
      @@client.delete "/v2/repositories/#{settings.user}/#{settings.repository}/tags/#{tag}/"
    end
  end

  def run
    tags = [] of String

    fetch_tags do |result|
      tags += result.map &.["name"].as_s
    end

    puts "Existings tags are #{tags.join(' ')}"

    delete_from = tags.size - (tags.size - settings.keep)
    tags_to_delete = tags.delete_at(delete_from..tags.size)
    delete tags_to_delete unless settings.dry

    puts "This is a dry run. Would delete the tags #{tags_to_delete.join(' ')}" if settings.dry
    puts "The following tags were deleted #{tags_to_delete.join(' ')}" unless settings.dry
  rescue IndexError
    puts "No tags to delete"
  rescue InvalidCredentials
    puts "Unable to login with the provided credentials"
  rescue UnknownResponse
    puts "Server returned a response that can't be handled"
  rescue e
    puts "Unknown error #{e.message}"
  end
end
