module Api
  class SessionsController < Api::ApplicationController
    before_action :authenticate_account, only: [:destroy]

    # login
    def create
      # TODO: why don't we have a unique constraint on email????
      account = Account.where("lower(email) = ? AND account_status = ?", params[:Email].downcase, 'ACTIVE').first
      if account and account.valid_password?(params[:Password])
        
        
        # but only if we're coming in without the proper account_device_id etc
        account.destroy_tokens

        # create dat new token though
        account_token = AccountToken.create(
          :token => account.provision_token, # TODO: use the account looping feature to ensure uniqueness son,
          :account_id => account.account_id,
          :account_device_id => nil, # meh meh meh meh
          :expires_at => DateTime.now + 30.days
        )

        # handle dat name collision bizniss

        # NO such thing as invalid accounts at this point, who cares about missing patients and such
        # TODO: scope this with some client version and header checks as this is some sketchy stuff
        json = account.legacy_api_json()
        render json: json, status: 200
      else

        # condition 1 - we have valid account. but incorrect password
        # TODO: add in rate limiting
        # TODO: add in failed attempt logging
        # TODO: add in lockout mechanism
        # TODO: this is dangerous in the name of UX
        if account and !account.valid_password?(params[:Password])
          render json: {
            :success => false,
            :message => "Incorrect password"
          }, status: 400
          return
        end

        # condition 2 (catch all) - we have neither
        # debateable security vs usability 401 vs 404
        render json: {
          :success => false,
          :message => "Unauthorized: Invalid email or auth token"
        }, status: 401
      end
    end

    # logout
    def destroy
      if params[:device_token].present?

        # TODO: take this logic past MVP level son
        # remove any device endpoints… yea son
        # the safer route would be to nil out the target_arn vs deleting the device entries, as we are likely going to build upon those records, and use for auditing / auth, etc

        # only android was calling this endpoint, so it's not necessary to go gangbusters with wiping the shared auth_token, at this point
        device = AccountDevice.where(:account_id => @account.account_id, :device_token => params[:device_token]).first
        if device != nil
          device.endpoint_arn = nil # disqualifies this device from being queued for receiving push
          device.save
        end

        # destroy da token, written terribly, this access here should be in some filter decorator business on the request, lolzin
        if request.headers['Authorization'] && request.headers['Authorization'].include?("Bearer")
          token = request.headers['Authorization'].split(" ")[1]
          # this is so verbose
          account_token = AccountToken.where(:token => token).first
          if account_token != nil
            account_token.destroy
          end
        else
          @account.destroy_tokens
        end

      else
        # original behavior to wipe the single, legacy token y'all
        # however will not destroy tokens with a device_id, e.g. if you have
        # other devices running newer clients, those are safe
        @account.destroy_tokens
      end

      # do the trashing of tokens though in the spirit of the old behaviors
      # delete any existing tokens in the "naked" namespace      

      render :json => {:success=>true}
    end

  end
end
