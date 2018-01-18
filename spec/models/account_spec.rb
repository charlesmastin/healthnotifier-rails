require 'spec_helper'

# GTHIAHB

describe Account do
  context "instantiated without arguments" do
    it { expect(subject).to be_invalid }
  end
  context "created with required arguments" do
    subject { Account.create! email: 'spec-tester@lifesquare.com', password: 'password1234' }
    it { expect(subject)                    .to     be_valid }
    it { expect(subject.account_id)         .to_not be_nil }
    it { expect(subject.email)              .to_not be_empty }
    it { expect(subject.encrypted_password) .to_not be_empty }
    it { expect(subject.active?)            .to     be true }
    it { expect(subject.patient?)           .to     be true }
    it { expect(subject.provider?)          .to     be false }
    it { expect(subject.approved_provider?) .to     be false }
    context ", then changed into a provider" do
      before { subject.provider! }
      it { expect(subject)                    .to     be_valid }
      it { expect(subject.patient?)           .to     be false }
      it { expect(subject.provider?)          .to     be true }
      it { expect(subject.approved_provider?) .to     be false }
      context ", then added a patient" do
        before do
          acctid = subject.account_id
          @pat = Patient.seed( # !!! use seed_fu instead of create! because create_user is required but read_only
            :account_id, :create_user, :update_user, :birthdate,
            {account_id: acctid, create_user: acctid, update_user: acctid, birthdate: '01/01/2001'})[0]
        end
        it { expect(subject)                    .to     be_valid }
        it { expect(subject.patients.size)      .to     eq(1) }
        it { expect(subject.approved_provider?) .to     be false }
        context ", then added a provider credential" do
          before do
            @provcred = @pat.provider_credentials.create!(
              expiration:               '2015-05-05',
              license_number:           '0123456789ABCDEF',
              licensing_state_province: 'California',
              licensing_country:        'US',
              licensing_board:          'Board of Boards',
              supervisor_name:          'Superman',
              supervisor_contact_email: 'kent@smallville.com',
              supervisor_contact_phone: '(123) 456-7890')
          end
          it { expect(subject)                        .to     be_valid }
          it { expect(@pat.provider_credentials.size) .to     eq(1) }
          it { expect(@provcred.accepted?)            .to     be false }
          it { expect(subject.approved_provider?)     .to     be false }
          context ", then accepted credential" do
            before { @provcred.accepted! }
            it { expect(subject)                    .to     be_valid }
            it { expect(@provcred.accepted?)        .to     be true }
            it { expect(subject.approved_provider?) .to     be true }
          end
        end
      end
    end
  end
end
