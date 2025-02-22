module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    session[:identifier].present?
  end

  def require_authentication
    authenticated? || request_authentication
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to new_session_path
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || root_url
  end

  def start_new_session_for(identifier:, app_password:)
    session[:identifier] = identifier
    session[:app_password] = app_password
    session[:user_agent] = request.user_agent
    session[:ip_address] = request.remote_ip
    session[:created_at] = Time.current
  end

  def terminate_session
    session.clear
  end
end
