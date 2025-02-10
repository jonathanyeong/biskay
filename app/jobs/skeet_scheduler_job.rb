class SkeetSchedulerJob < ApplicationJob
  queue_as :default
  BASE_URL = "https://bsky.social"

  def perform(skeet_id: nil)
    skeet = Skeet.find(skeet_id)
    user = skeet.user
    content = skeet.content
    session = create_session(user)
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
    facets = tag_facets(content) + mention_facets(content)
    request_body = {
      repo: session["did"],
      collection: "app.bsky.feed.post",
      record: {
        text: content.gsub(/<a href="[^"]*">|<\/a>/, ""),  # Remove HTML tags but keep link text
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

  def tag_facets(content)
    facets = []
    tag_pattern = /#\S+/
    matches = content.to_enum(:scan, tag_pattern).map { { tag: Regexp.last_match, indices: Regexp.last_match.offset(0) } }
    matches.each do |match|
      tag = match[:tag].to_s[1..-1] # Trim leading hashtag
      indices = match[:indices]
      facets << {
        index: {
          byteStart: indices[0],
          byteEnd: indices[1]
        },
        features: [ {
          "$type": "app.bsky.richtext.facet#tag",
          tag: tag
        } ]
      }
    end
    facets
  end

  def mention_facets(content)
    facets = []
    # regex based on: https://atproto.com/specs/handle#handle-identifier-syntax
    mention_pattern = /[$|\W](@([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)/
    matches = content.to_enum(:scan, mention_pattern).map { { handle: Regexp.last_match, indices: Regexp.last_match.offset(0) } }
    matches.each do |match|
      handle = match[:handle].to_s.strip[1..-1] # Trim leading @
      indices = match[:indices]
      resp = conn.get("/xrpc/com.atproto.identity.resolveHandle", { handle: handle })
      # TODO: Add error handling
      handle_did = JSON.parse(resp.body)["did"]
      facets << {
        index: {
          byteStart: indices[0],
          byteEnd: indices[1]
        },
        features: [ {
          "$type": "app.bsky.richtext.facet#mention",
          did: handle_did
        } ]
      }
    end
    facets
  end
end
