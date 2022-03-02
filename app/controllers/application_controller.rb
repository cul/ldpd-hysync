class ApplicationController < ActionController::Base
  def authenticate_http_basic!
    authenticate_or_request_with_http_basic do |username, password|
      # Note: Good to use secure_compare rather than regular string comparison becaue we're dealing with a password.
      # "The values are first processed by SHA256, so that we don't leak length info via timing attacks."
      # https://api.rubyonrails.org/classes/ActiveSupport/SecurityUtils.html#method-c-secure_compare

      HYSYNC[:remote_request_username].present? && HYSYNC[:remote_request_password].present? &&
       ActiveSupport::SecurityUtils.secure_compare(username, HYSYNC[:remote_request_username]) &&
       ActiveSupport::SecurityUtils.secure_compare(password, HYSYNC[:remote_request_password])
    end
  end
end
