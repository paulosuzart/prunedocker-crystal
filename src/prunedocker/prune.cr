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
      raise InvalidCredentials.new if response.status_code != 200
      JSON.parse(response.body_io)["token"].as_s
    end
  end

  private def tags
    @@client.get "/v2/repositories/#{settings.user}/#{settings.repository}/tags/" do |response|
      puts response.body_io.gets_to_end
    end
  end

  def run
    # pay = JSON.parse(%({"token": "eyJ4NWMiOlsiTUlJQytUQ0NBcCtnQXdJQkFnSUJBREFLQmdncWhrak9QUVFEQWpCR01VUXdRZ1lEVlFRREV6dFJORm96T2tkWE4wazZXRlJRUkRwSVRUUlJPazlVVkZnNk5rRkZRenBTVFRORE9rRlNNa002VDBZM056cENWa1ZCT2tsR1JVazZRMWsxU3pBZUZ3MHhOekEzTURZd01EUXpOVGxhRncweE9EQTNNRFl3TURRek5UbGFNRVl4UkRCQ0JnTlZCQU1UTzBGS1Z6VTZTVUUyV0RwVFNsVkdPbG8zVjBjNlZrOVJOenBXUzBsUk9qSldSa0U2VDBjeVN6cFpWa0V5T2taT1dGZzZTVkpSTWpvMlJsVklNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQW5uSTFTeTQ5ODZ6WmpRRk5Hb1NzQUVwMlRubjBUWGNkcnk1ZTd2UkZVemJaUDBHUDVzUVFKaXVaazNISlhnTVVPbjc5OFNCSW5sVHFyYXFCS1wvZXZGRlhSNCszVFVGTll2d2QrS2M4NkIreHBKMGFUZ0FNMzg3VVBrYzNPWUhWNTk1TmZWR2NQQnI3NlpiczBLc2ZjYlRDY0c4aDZZR1ZEV1NPa1ZzdFFBaW1ubEdxRitPMlBPVDV4QUNEOWttb0JTU0RJMnRrTjZTdnV5cHMzZFVwVVNtMVRGYTErQyt2dG9iM21BcFBmTElmMnJTMGxHeng5WDN6NHYyaWErY1RXRDdqQmw4cnJIaTRUZmpVeXVIeEo0QU9kUk51cGdqZzRpOFRvc0FEVGJHTmh6OVhNeUpVNU13K2ZMaWxmSFB3UXh6Yk5Pb0pYUjdYV0JObDFNeUwrUHdJREFRQUJvNEd5TUlHdk1BNEdBMVVkRHdFQlwvd1FFQXdJSGdEQVBCZ05WSFNVRUNEQUdCZ1JWSFNVQU1FUUdBMVVkRGdROUJEdEJTbGMxT2tsQk5sZzZVMHBWUmpwYU4xZEhPbFpQVVRjNlZrdEpVVG95VmtaQk9rOUhNa3M2V1ZaQk1qcEdUbGhZT2tsU1VUSTZOa1pWU0RCR0JnTlZIU01FUHpBOWdEdFJORm96T2tkWE4wazZXRlJRUkRwSVRUUlJPazlVVkZnNk5rRkZRenBTVFRORE9rRlNNa002VDBZM056cENWa1ZCT2tsR1JVazZRMWsxU3pBS0JnZ3Foa2pPUFFRREFnTklBREJGQWlFQVwvY090U0hpVFdlTnFYSGdxclpQRVZXZFwvZXhTOGh1ZWtBVjR3akFENlBNa0NJRCtZdG9oNU1Fa2ZZM3BmT3NUSDdjbDdkZEJObjlqUDM0SmdhMGlIYjM2OCJdLCJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE1MTg3Mjg5NTUsImV4cCI6MTUyMTMyMDk1NSwidXNlcm5hbWUiOiJyb3VuZHBlZ3MiLCJzdWIiOiI5ZWQ1ODg2NTcwZDI0YzgwOGMzOWU2YjJkZmQ3ZmFmMSIsInVzZXJfaWQiOiI5ZWQ1ODg2NTcwZDI0YzgwOGMzOWU2YjJkZmQ3ZmFmMSIsImp0aSI6IjA5RkQ0MzBFOENDMkRERDYwNkE5Q0UxNTRFQkFGRTA1IiwiZW1haWwiOiIiLCJzZXNzaW9uX2lkIjoiMDlGRDQzMEU4Q0MyRERENjA2QTlDRTE1NEVCQUZFMDUifQ.lG6sxoOOqjCiPz4nt-GU5WJnbotHEWiykzivk8Ng03hw9ciqOF5sxjShRh2RFGgf0EZIZNsTG1e9eTbnGo3q85l8DT_tZLMhIwtdvtwRD105gPl7bQ155hllI-YydDFcYdGNcIDg4s6BMUKlWyC4jP1SiBDZuCahMOv_Wp64VYZMpJJc8nLvLX1WjGxlOhyRZAGlCcRShUi_pxqMOrKbeLQ4Sl9K0E7XaZjGwPa_1v4Hf_SYnDKvcXavgZG_QwGQwucrnopLGJfMArPqex5yTp7GmK4W61c0vzhpcDhEKEBMKmuXm4PjHVVU00YiaVxxMTvs818xHDVF5Gl_rzunVg"}))
    # puts pay["token"]
    tags
  rescue InvalidCredentials
    puts "Unable to login with the provided credentials"
  rescue UnknownResponse
    puts "Server returned a response that can't be handled"
  end
end
