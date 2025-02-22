class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  def new
  end

  def create
    start_new_session_for(identifier: user_params[:identifier], app_password: user_params[:app_password])
    redirect_to after_authentication_url
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  private

  def user_params
    params.permit(:identifier, :app_password)
  end
end
