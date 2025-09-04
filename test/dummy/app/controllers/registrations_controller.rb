class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
  end

  def create
    user = User.new(username: registration_params[:username], password: registration_params[:password], password_confirmation: registration_params[:password_confirmation])

    if user.save
      start_new_session_for user

      redirect_to after_authentication_url, notice: "User registered successfully"
    else
      redirect_to new_registration_path, alert: "Error registering user"
    end
  end

  private

  def registration_params
    params.require(:registration).permit(:username, :password, :password_confirmation)
  end
end
