class PatientNetworkController < ApplicationController
    before_action :authenticate_account!

    def show_all_pending_invites
        @privacy_options = Values.call('privacy')
        @pending = @current_account.pending_invites
    end

end