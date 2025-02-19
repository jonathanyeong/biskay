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
    processed_content, mkdown_facets = process_markdown_links(content)

    facets = mkdown_facets + tag_facets(processed_content) + mention_facets(processed_content) + url_facets(processed_content)
    request_body = {
      repo: session[:user]["did"],
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
      # There's something off here. It would be nice to pass in a public URL to resolve handle. Maybe this needs to be done outside this func.
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

  def mkdown_links(content)
    mkdown_links = []
    url_pattern = /\[(?<text>[^\]]+)\]\((?<url>https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*[-a-zA-Z0-9@%_\+~#\/\/=])?)\)/
    matches = content.to_enum(:scan, url_pattern).map { Regexp.last_match }

    mkdown_links = []
    matches.each do |match|
      mkdown_links << {
        text: match[:text],
        link: match[:url],
        match: match.to_s
      }
    end
    mkdown_links
  end

  def process_markdown_links(content)
    facets = []
    result_text = content.dup

    links = mkdown_links(content)

    links.reverse_each do |link|
      start_pos = result_text.index(link[:match])

      if start_pos
        end_pos = start_pos + link[:match].length

        facets << {
          index: {
            byteStart: start_pos,
            byteEnd: start_pos + link[:text].length
          },
          features: [ {
            "$type": "app.bsky.richtext.facet#link",
            uri: link[:link]
          } ]
        }

        result_text[start_pos...end_pos] = link[:text]
      end
    end

    [ result_text, facets ]
  end

  def url_facets(content)
    facets = []
    # partial/naive URL regex based on: https://stackoverflow.com/a/3809435
    # tweaked to disallow some training punctuation
    url_pattern = /([$|\W])(https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*[-a-zA-Z0-9@%_\+~#\/\/=])?)/
    matches = content.to_enum(:scan, url_pattern).map { { url: Regexp.last_match, indices: Regexp.last_match.offset(0) } }
    matches.each do |match|
      url = match[:url].to_s[1..-1]
      indices = match[:indices]
      facets << {
        index: {
          byteStart: indices[0],
          byteEnd: indices[1]
        },
        features: [ {
          "$type": "app.bsky.richtext.facet#link",
          uri: url
        } ]
      }
    end
    facets
  end
end
