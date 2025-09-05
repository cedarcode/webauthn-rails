class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
  end

  def create
    if registration_params[:password] != registration_params[:password_confirmation]
      redirect_to new_registration_path, alert: "Password and confirmation do not match"
      return
    end
    user = User.new(email_address: registration_params[:email_address], password: registration_params[:password])

    if user.save
      start_new_session_for user

      redirect_to after_authentication_url, notice: "User registered successfully"
    else
      flash[:alert] = @user.errors.full_messages.join("\n")
      render :new
    end
  end

  private

  def registration_params
    params.require(:registration).permit(:email_address, :password, :password_confirmation)
  end
end
