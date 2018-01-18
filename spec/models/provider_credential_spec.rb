require 'spec_helper'
require 'securerandom'

describe ProviderCredential do
  def create_provider_credential
    uuid = SecureRandom.uuid
    email = "#{uuid}@lifesquare.com"
    account = Account.create! email: email, password: uuid
    account.save
    patient = account.patients.create({ create_user: account.account_id, update_user: account.account_id, birthdate: '1980-01-01' })
    patient.save
    expiration = DateTime.now + 365
    provider_credentials = patient.provider_credentials.create(
      expiration: expiration,
      license_number: uuid,
      licensing_country: 'US',
      licensing_board: 'CA',
      supervisor_name: 'John Doe',
      supervisor_contact_email: 'johndoe@aol.com',
      supervisor_contact_phone: '1234567890'
    )
    provider_credentials.save
    provider_credentials
  end
  before (:each) do
    @subject = create_provider_credential
  end
  context "instantiated without arguments" do
    it { expect(@subject).to be_valid }
    it { expect(@subject.pending?)  .to be true }
    it { expect(@subject.accepted?) .to be false }
    it { expect(@subject.expired?)  .to be false }
    it { expect(@subject.rejected?) .to be false }
  end
  context "change status to accepted" do
    before { @subject.accepted! }
    it { expect(@subject.accepted?) .to be true }
    it { expect(@subject.expired?)  .to be false }
    it { expect(@subject.pending?)  .to be false }
    it { expect(@subject.rejected?) .to be false }
  end
  context "change status to expired" do
    before { @subject.expired! }
    it { expect(@subject.expired?)  .to be true }
    it { expect(@subject.accepted?) .to be false }
    it { expect(@subject.pending?)  .to be false }
    it { expect(@subject.rejected?) .to be false }
  end
  context "change status to rejected" do
    before { @subject.rejected! }
    it { expect(@subject.rejected?) .to be true }
    it { expect(@subject.accepted?) .to be false }
    it { expect(@subject.expired?)  .to be false }
    it { expect(@subject.pending?)  .to be false }
  end
  context "change status back to pending" do
    before do
      @subject.accepted!
      @subject.expired!
      @subject.rejected!
      @subject.pending!
    end
    it { expect(@subject.pending?)  .to be true }
    it { expect(@subject.accepted?) .to be false }
    it { expect(@subject.expired?)  .to be false }
    it { expect(@subject.rejected?) .to be false }
  end
end
