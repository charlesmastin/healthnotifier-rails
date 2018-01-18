require 'jwt'

module Api
  class OauthController < Api::ApplicationController
    # bearer on this bizzle
    # TODO: wire standard spec level response handlers
    def grant
      # form inbound per spec son
      # operate only if grant_type is password
      # unless return with a 400ish or something blablabla
      if params[:grant_type] == "password"
        account = Account.where("lower(email) = ? AND account_status = ?", params[:username].downcase, 'ACTIVE').first
        if account and account.valid_password?(params[:password])

          # this is really not necessary though, firebombing
          # account.destroy_tokens

          duration = 12.hours

          # signed son
          payload = {
            :iss => "lifesquare",
            :exp => (DateTime.now + duration).to_i,
            :iat => DateTime.now.to_i,
            :lifesquare_provider => account.provider?,
            :lifesquare_account_uuid => account.uid
          }
          token = JWT.encode payload, Rails.configuration.lifesquareapi[:hmac_secret], 'HS256'

          # TODO: refresh_token
          account_token = AccountToken.create(
            :token => token, # TODO: use the account looping feature to ensure uniqueness son,
            :account_id => account.account_id,
            :account_device_id => nil, # meh meh meh meh
            :expires_at => DateTime.now + duration
          )
          # we are not caring about client reading of this access token bro, because we're not ever going to share our signing key

          # more oauthy up in this bizz
          render json: {
            :access_token => token,
            :token_type => "bearer",
            :expires_in => duration.to_i
          }, status: 200
        else

          # sucks to be you son, look up the Oauth spec for this error
          render json: {
            :success => false,
            :message => "Unauthorized: Invalid email or auth token"
          }, status: 401

        end
      end

      if params[:grant_type] == "refresh_token"
        # if we had a refresh_token though
      end

    end

    def revoke
      # simply delete the token, no more no less
      # https://tools.ietf.org/html/rfc7009
    end

  end
end