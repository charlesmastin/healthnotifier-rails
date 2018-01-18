require 'spec_helper'

describe PatientNetwork do
  let (:patient_a) {
    # !!! must used seed instead of create! because null column constraint fails with create_user
    Patient.seed(
      :create_user, :first_name, :last_name,
      {account_id: 1,
       create_user: 1,
       update_user: 1,
       first_name:  'Anna',
       last_name:   'Zodiac',
       birthdate:   '1970-07-07'
      })[0]
  }
  let (:patient_b) {
    # !!! must used seed instead of create! because null column constraint fails with create_user
    Patient.seed(
      :create_user, :first_name, :last_name,
      {account_id: 2,
       create_user: 2,
       update_user: 2,
       first_name:  'Burt',
       last_name:   'Yonder',
       birthdate:   '1980-08-08'
      })[0]
  }
  context "instantiated without associations" do
    pending ": implement validation of associations" do
      it {should be_invalid}
    end
  end
  context "created for granter patient A having auditor patient B" do
    subject {PatientNetwork.create! granter_patient: patient_a, auditor_patient: patient_b}
    it                    {should be_valid }
    its(:granter_patient) {should equal patient_a}
    its(:auditor_patient) {should equal patient_b}
  end
  context "created for granter patient B having auditor patient A" do
    subject {PatientNetwork.create! granter_patient: patient_b, auditor_patient: patient_a}
    it                    {should be_valid }
    its(:granter_patient) {should equal patient_b}
    its(:auditor_patient) {should equal patient_a}
  end
end
