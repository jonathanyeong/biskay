class SkeetSchedulerJob < ApplicationJob
  queue_as :default

  def perform(content: nil, identifier: nil, password: nil)
    response = conn.post("/xrpc/com.atproto.server.createSession") do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = JSON.generate({
        identifier: identifier,
        password: password
      })
    end
    user = JSON.parse(response.body)

    current_time = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ")

    request_body = {
      repo: user["did"],
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
      req.headers["Authorization"] = "Bearer #{user["accessJwt"]}"
      req.body = JSON.generate(request_body)
    end

    resp = JSON.parse(response.body)
    puts resp
  end
end
