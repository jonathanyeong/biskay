class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for @user
      redirect_to after_authentication_url
    else
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:identifier, :app_password)
  end
end
