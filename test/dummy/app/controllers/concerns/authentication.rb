module Authentication
  extend ActiveSupport::Concern

  def current_user
    @current_user ||=
    if session[:user_id]
      User.find_by(id: session[:user_id])
    end
  end

  def enforce_no_current_user
    if current_user.present?
      redirect_to main_app.root_path
    end
  end

  def enforce_current_user
    if current_user.blank?
      redirect_to main_app.new_session_path
    end
  end

  def sign_in(user)
    session[:user_id] = user.id
  end

  def sign_out
    session[:user_id] = nil
  end
end
