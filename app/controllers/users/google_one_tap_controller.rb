
class GoogleOneTapController < ApplicationController

  def google_onetap
    pp params

    if g_csrf_token_valid?
      payload = Google::Auth::IDTokens.verify_oidc(params[:credential], aud: ENV.fetch('GOOGLE_CLIENT_ID'))
      puts "data is:"
      pp payload
      code = "data['client_id']"
      Rails.cache.write(oauth_token_cache_key(code), data['uid'], expires_in: 1.minute)
      redirect_to ENV.fetch('REDIRECT_SUCCESS_URL') + "?code=#{code}&origin=#{redirect_url}", allow_other_host: true
    else
      redirect_to ENV.fetch('REDIRECT_FAIL_URL'), allow_other_host: true
    end
  end

  private

  def g_csrf_token_valid?
    cookies['g_csrf_token'] == params['g_csrf_token']
  end

  def redirect_url
    false || ENV.fetch('REDIRECT_SUCCESS_URL')
  end

  def oauth_token_cache_key(code)
    "#{ENV.fetch('APPLICATION_NAME')}_oauth_token_#{code}"
  end
end