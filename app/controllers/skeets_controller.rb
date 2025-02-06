class SkeetsController < ApplicationController
  BASE_URL = "https://bsky.social"
  def index
    # Identifier must be without the @.

    # https://docs.bsky.app/blog/create-post#authentication
    # > com.atproto.server.createSession API endpoint returns a session object containing two API tokens: an access token (accessJwt)
    # > which is used to authenticate requests but expires after a few minutes
    # Always reauthenticate when you get back to this page.
    response = conn.post("/xrpc/com.atproto.server.createSession") do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = JSON.generate({
        identifier: ENV["BLUESKY_HANDLE"],
        password: ENV["BLUESKY_PASSWORD"]
      })
    end
    # TODO: Configurable timezone
    Time.zone = "Eastern Time (US & Canada)"
    @current_datetime = Time.zone.now
    session[:user] = JSON.parse(response.body)
  end

  def create
    # Parse the body and transform some of the markup into the correct things (like links)
    # Handle scheduling
    content = params[:content]
    # TODO: Add alert

    Time.zone = "Eastern Time (US & Canada)"
    scheduled_at = params["scheduled_at"]
    scheduled_datetime = Time.zone.local(
      scheduled_at["datetime(1i)"],
      scheduled_at["datetime(2i)"],
      scheduled_at["datetime(3i)"],
      scheduled_at["datetime(4i)"],
      scheduled_at["datetime(5i)"]
    )
    return redirect_to root_url if content.blank? || content.length > 300

    if scheduled_datetime > Time.zone.now
      SkeetSchedulerJob.set(wait_until: scheduled_datetime).perform_later(content: content, identifier: ENV["BLUESKY_HANDLE"], password:  ENV["BLUESKY_PASSWORD"])
      return redirect_to root_url
    end

    puts "CONTINUING TO BSKY"
    current_time = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ")

    request_body = {
      repo: session[:user]["did"],
      collection: "app.bsky.feed.post",
      record: {
        text: content.gsub(/<a href="[^"]*">|<\/a>/, ""),  # Remove HTML tags but keep link text
        facets: [],
        createdAt: current_time,
        "$type": "app.bsky.feed.post"
      }
    }

    response = conn.post("/xrpc/com.atproto.repo.createRecord") do |req|
      req.headers["Content-Type"] = "application/json"
      req.headers["Authorization"] = "Bearer #{session[:user]["accessJwt"]}"
      req.body = JSON.generate(request_body)
    end

    resp = JSON.parse(response.body)
    puts resp
    # rescue Faraday::ResourceNotFound => e
    #   raise "Failed to post: The API endpoint returned 404. Please check if you're authenticated and using the correct API endpoint."
    # rescue Faraday::Error => e
    #   raise "Failed to post: #{e.message}"
    redirect_to root_url
  end

  private

  def conn
    @conn ||= Faraday.new(url: BASE_URL) do |f|
      f.request :json
    end
  end
end
