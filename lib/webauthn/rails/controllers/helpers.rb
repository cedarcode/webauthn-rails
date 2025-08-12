module Webauthn
  module Rails
    module Controllers
      module Helpers
        extend ActiveSupport::Concern

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

        ActiveSupport.on_load(:action_controller) do
          helper_method :current_user
        end
      end
    end
  end
end
