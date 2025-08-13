module Authentication
  extend ActiveSupport::Concern

  private

  def sign_in(user)
    session[:user_id] = user.id
  end

  def sign_out
    session[:user_id] = nil
  end

  def current_user
    @current_user ||=
      if session[:user_id]
        User.find_by(id: session[:user_id])
      end
  end

  def enforce_no_current_user
    if current_user.present?
      redirect_to root_path
    end
  end

  def enforce_current_user
    if current_user.blank?
      redirect_to new_session_path
    end
  end

  included do
    helper_method :current_user
  end
end
