require 'spec_helper'
require 'controller_spec_helpers'
require 'securerandom'

describe PatientsController do
  include ControllerSpecHelpers
  #before :all do
  #  Rails.application.reload_routes!
  #end
  describe 'provider credentials workflow:' do
    before :all do
      uuid = SecureRandom.uuid
      create_account_and_patient('provider',
        "#{uuid}@#{email_domain_devtest}", uuid,
        'Provider', 'Of', 'Sorrow', '1981-01-01', false) # NOT confirmed
    end
    after :all do
      destroy_account_and_patient 'provider'
    end
    # TODO: make this work with devise
#    context 'create provider credentials' do
#      it 'sends POST to #collection_write with JSON' do
#        sign_in (@account = @account_provider)
#        post :collection_write,
#          patient_id: @patient_provider.patient_id,
#          collection_name: 'provider_credentials',
#          provider_credentials: [{
#            status:                   'PENDING',
#            expiration:               '2015-05-05',
#            license_number:           '0123456789ABCDEF',
#            licensing_state_province: 'California',
#            licensing_country:        'US',
#            licensing_board:          'Board of Boards',
#            supervisor_name:          'Superman',
#            supervisor_contact_email: 'kent@smallville.com',
#            supervisor_contact_phone: '(123) 456-7890'
#          }]
#        puts "## response.body: #{response.body}"
#        expect(response.status).to eq(200)
#        sign_out @account
#      end
#    end
  end
end
