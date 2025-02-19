class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  def after_sign_in_path_for(resource)
    # Redirect to a specific path after sign in
    root_path # or any other path you want
  end
end
