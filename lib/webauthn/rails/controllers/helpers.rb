module Webauthn
  module Rails
    module Controllers
      module Helpers
        extend ActiveSupport::Concern

        class_eval <<-METHODS, __FILE__, __LINE__ + 1
          def current_#{Webauthn::Rails.resource_name}
            @current_resource ||=
              if session[:resource_id]
                Webauthn::Rails.resource_class.find_by(id: session[:resource_id])
              end
          end

          def enforce_no_current_#{Webauthn::Rails.resource_name}
            if current_#{Webauthn::Rails.resource_name}.present?
              redirect_to main_app.root_path
            end
          end

          def enforce_current_#{Webauthn::Rails.resource_name}
            if current_#{Webauthn::Rails.resource_name}.blank?
              redirect_to webauthn_rails.new_session_path
            end
          end
        METHODS

        ActiveSupport.on_load(:action_controller) do
          helper_method "current_#{Webauthn::Rails.resource_name}"
        end
      end
    end
  end
end
