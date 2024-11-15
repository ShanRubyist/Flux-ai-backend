class Users::GoogleOneTapController < ApplicationController
  def token
    if g_csrf_token_valid?
      payload = Google::Auth::IDTokens.verify_oidc(params[:credential], aud: ENV.fetch('GOOGLE_CLIENT_ID'))
      uid = payload['sub']
      if uid
        user = User.find_by(uid: uid)
        token = user.create_new_auth_token(params[:code])
        puts 'token is'
        puts token
        
        render json: {
          data: token
        }, status: 200
      else
        render json: {
          errors: [
            'credential is invalid'
          ]
        }, status: 500
      end
    end
  end

  private

  def g_csrf_token_valid?
    # cookies['g_csrf_token'] == params['g_csrf_token']
    true
  end

  def redirect_url
    params['origin'] || ENV.fetch('REDIRECT_SUCCESS_URL')
  end

  def oauth_token_cache_key(code)
    "#{ENV.fetch('APPLICATION_NAME')}_oauth_token_#{code}"
  end
end