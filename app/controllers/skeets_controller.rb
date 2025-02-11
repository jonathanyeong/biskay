class SkeetsController < ApplicationController
  BASE_URL = "https://bsky.social"
  def index
    @drafts = Skeet.draft.order(created_at: :desc)
    # Identifier must be without the @.

    # https://docs.bsky.app/blog/create-post#authentication
    # > com.atproto.server.createSession API endpoint returns a session object containing two API tokens: an access token (accessJwt)
    # > which is used to authenticate requests but expires after a few minutes
    # Always reauthenticate when you get back to this page.
    response = conn.post("/xrpc/com.atproto.server.createSession") do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = JSON.generate({
        identifier: Current.session.user.identifier,
        password: Current.session.user.app_password
      })
    end
    # TODO: Configurable timezone
    Time.zone = "Eastern Time (US & Canada)"
    @current_datetime = Time.zone.now
    session[:user] = JSON.parse(response.body)
  end

  def create
    # Parse the body and transform some of the markup into the correct things (like links)
    content = params[:content]
    # TODO: Handle blank submits (client side validation)
    return redirect_to root_url if content.blank?
    commit_action = params[:commit]

    case commit_action
    when "Save Draft"
      Skeet.create(content: content, user_id: Current.session.user.id, status: "draft")
      # TODO: Graceful error handling
    when "Post"
      # TODO: Add Flash message
      return redirect_to root_url if content.length > 300
      Skeet.create(content: content, user_id: Current.session.user.id, status: "published")
      post_to_bsky(content)
    when "Schedule"
      Time.zone = "Eastern Time (US & Canada)"
      scheduled_at = params["scheduled_at"]
      scheduled_datetime = Time.zone.local(
        scheduled_at["datetime(1i)"],
        scheduled_at["datetime(2i)"],
        scheduled_at["datetime(3i)"],
        scheduled_at["datetime(4i)"],
        scheduled_at["datetime(5i)"]
      )
      # Handle error
      skeet = Skeet.create(content: content, user_id: Current.session.user.id, status: "scheduled")
      SkeetSchedulerJob.set(wait_until: scheduled_datetime).perform_later(skeet_id: skeet.id)
      return redirect_to root_url
    end

    redirect_to root_url
  end

  def share
    skeet = Skeet.find(params[:skeet_id])
    post_to_bsky(skeet.content)
    # TODO: Shouldn't assume that the post to bsky worked
    skeet.published!
    redirect_to root_url
  end

  def search_actors
    resp = public_conn.get("/xrpc/app.bsky.actor.searchActorsTypeahead", { q: params[:q], limit: 8 })
    puts JSON.parse(resp.body)
    @actors = JSON.parse(resp.body)["actors"]

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("mentions-dropdown", partial: "skeets/actor_suggestions", locals: { actors: @actors }) }
    end
  end

  private

  def conn
    @conn ||= Faraday.new(url: BASE_URL) do |f|
      f.request :json
    end
  end

  def public_conn
    @public_conn ||= Faraday.new(url: "https://public.api.bsky.app") do |f|
      f.request :json
    end
  end

  def post_to_bsky(content)
    current_time = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ")
    facets = tag_facets(content) + mention_facets(content)
    request_body = {
      repo: session[:user]["did"],
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
      req.headers["Authorization"] = "Bearer #{session[:user]["accessJwt"]}"
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
