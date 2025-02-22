require "bsky_parser"

class SkeetSchedulerJob < ApplicationJob
  queue_as :default
  BASE_URL = "https://bsky.social"

  def perform(skeet_id: nil)
    skeet = Skeet.find(skeet_id)
    content = skeet.content
    session = create_session(skeet.bsky_user)
    post_to_bsky(content, session)
  end

  private

  def create_session(user)
    response = conn.post("/xrpc/com.atproto.server.createSession") do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = JSON.generate({
        identifier: user.identifier,
        password: user.app_password
      })
    end
    JSON.parse(response.body)
  end

  def conn
    conn ||= Faraday.new(url: BASE_URL) do |f|
      f.request :json
    end
  end

  def post_to_bsky(content, session)
    current_time = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ")
    processed_content, facets = BskyParser.parse(content)
    request_body = {
      repo: session["did"],
      collection: "app.bsky.feed.post",
      record: {
        text: processed_content,
        facets: facets,
        createdAt: current_time,
        "$type": "app.bsky.feed.post"
      }
    }

    conn.post("/xrpc/com.atproto.repo.createRecord") do |req|
      req.headers["Content-Type"] = "application/json"
      req.headers["Authorization"] = "Bearer #{session["accessJwt"]}"
      req.body = JSON.generate(request_body)
    end
  end
end
