module ControllerSpecHelpers
  def create_account_and_patient(
        suffix, email, password,
        first_name, middle_name, last_name, birthdate,
        confirmed = true, searchable = true)
    instance_variable_set(acctvarname = "@account_#{suffix}",
      Account.create!(
        email:        email,
        password:     password))
    acctid = instance_variable_get(acctvarname).account_id
    #puts "## CREATED Account: #{acctid}/#{instance_variable_get(acctvarname).email}"
    instance_variable_set(patvarname = "@patient_#{suffix}",
      Patient.seed( # !!! use seed_fu instead of create! because create_user is required but read_only
        :account_id, :create_user, :first_name, :last_name,
        {account_id:  acctid,
         create_user: acctid,
         update_user: acctid,
         first_name:  first_name,
         middle_name: middle_name,
         last_name:   last_name,
         birthdate:   birthdate,
         confirmed:   confirmed,
         searchable:  searchable})[0])
    patid = instance_variable_get(patvarname).patient_id
    #puts "## CREATED Patient: #{patid}/#{instance_variable_get(patvarname).fullname}"
  end
  def destroy_account_and_patient(suffix)
    instance_variable_get("@account_patient_#{suffix}").destroy if instance_variable_get("@account_patient_#{suffix}")
    instance_variable_get("@patient_#{suffix}").destroy if instance_variable_get("@patient_#{suffix}")
    instance_variable_get("@account_#{suffix}").destroy if instance_variable_get("@account_#{suffix}")
  end
  def email_domain_application
    'lifesquare.com'
  end
  def email_domain_devtest
    @email_domain_devtest ||= (ENV['RAILS_EMAIL_DOMAIN_DEVTEST'] || email_domain_application)
  end
end
