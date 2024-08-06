class Users::OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController

  # def omniauth_success
  #   super
  # end

  # def redirect_callbacks
  #   super
  # end

  def render_data_or_redirect(message, data, user_data = {})
    if message == 'deliverCredentials'
      code = data['client_id']
      Rails.cache.write(oauth_token_cache_key(code), data['uid'], expires_in: 1.minute)
      redirect_to ENV.fetch('REDIRECT_SUCCESS_URL') + "?code=#{code}", allow_other_host: true

    elsif message == 'authFailure'
      redirect_to ENV.fetch('REDIRECT_FAIL_URL'), allow_other_host: true
    end
  end

  def oauth_token_cache_key(code)
    "#{ENV.fetch('APPLICATION_NAME')}_oauth_token_#{code}"
  end

  def token
    uid = Rails.cache.fetch(oauth_token_cache_key(params[:code])) { nil }
    # Rails.cache.delete(oauth_token_cache_key(params[:code]))

    if uid
      user = User.find_by(uid: uid)
      token = user.create_new_auth_token(params[:code])

      render json: {
        data: token
      }, status: 200
    else
      render json: {
        errors: [
          'code is invalid'
        ]
      }, status: 500
    end
  end
end