class ProviderController < ApplicationController
    before_action :authenticate_account!

    def register
        # basically a stub for the html form
        # ---------
        @us_states = Values.call('state')

        # redirect to discourage repeat submissions
        if current_account.provider?
            redirect_to(edit_account_path)
        else
            # check any in-progress bits son
            creds = current_account.pending_provider_credentials
            if creds.count > 0
                redirect_to(edit_account_path)
                return
            end
            unless current_account.active_patients.count > 0
                flash[:notice] = 'Must have at least one active profile to register as a health care provider'
                redirect_to(patient_index_path)
                return
            end
        end
    end

end