class SkeetsController < ApplicationController
  BASE_URL = "https://bsky.social"
  class AuthenticationError < StandardError; end
  class ValidationError < StandardError; end

  def index
    puts "#{ENV["BLUESKY_HANDLE"]} #{ENV["BLUESKY_PASSWORD"]}"
    puts conn.inspect
    # Identifier must be without the @.
    puts JSON.generate({
      identifier: ENV["BLUESKY_HANDLE"],
      password: ENV["BLUESKY_PASSWORD"]
    })
    response = conn.post("/xrpc/com.atproto.server.createSession") do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = JSON.generate({
        identifier: ENV["BLUESKY_HANDLE"],
        password: ENV["BLUESKY_PASSWORD"]
      })
    end

    puts response.inspect
    session[:user] = JSON.parse(response.body)
  end

  def create
    # current_time = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ")

    # request_body = {
    #   repo: @session["did"],
    #   collection: "app.bsky.feed.post",
    #   record: {
    #     text: text.gsub(/<a href="[^"]*">|<\/a>/, ""),  # Remove HTML tags but keep link text
    #     facets: [],
    #     createdAt: current_time,
    #     "$type": "app.bsky.feed.post"
    #   }
    # }

    #   response = connection.post("/xrpc/com.atproto.repo.createRecord") do |req|
    #     req.headers["Content-Type"] = "application/json"
    #     req.headers["Authorization"] = "Bearer #{@session["accessJwt"]}"
    #     req.body = JSON.generate(request_body)
    #   end

    #   JSON.parse(response.body)
    # rescue Faraday::ResourceNotFound => e
    #   raise "Failed to post: The API endpoint returned 404. Please check if you're authenticated and using the correct API endpoint."
    # rescue Faraday::Error => e
    #   raise "Failed to post: #{e.message}"
  end

  private

  def conn
    @conn ||= Faraday.new(url: BASE_URL) do |f|
      f.request :json
    end
  end
end
