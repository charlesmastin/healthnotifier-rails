require 'date'

module Athenanet

  @@athenanet_base_url = nil
  @@athenanet_access_token = nil
  @@athenanet_expire_time = nil

  def self.authenticate
    if @@athenanet_access_token.nil? or @@athenanet_expire_time.nil? or (Time.now.to_i > @@athenanet_expire_time)
      @@athenanet_base_url = Rails.application.config.athenanet[:base_url] unless @@athenanet_base_url
      key = Rails.application.config.athenanet[:key]
      secret = Rails.application.config.athenanet[:secret]
      uri = URI.parse "#{@@athenanet_base_url}/oauthpreview/token"
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true;
      request = Net::HTTP::Post.new(uri.path)
      request.basic_auth key, secret
      request.set_form_data({"grant_type" => "client_credentials"})
      response = http.request(request)
      data = JSON.parse response.body
      @@athenanet_access_token = data['access_token']
      @@refresh_token = data['refresh_token']
      @@athenanet_expire_time = Time.now.to_i + data['expires_in']
    end
    @@athenanet_access_token
  end

  def self.patient_search(first_name, last_name, date_of_birth, phone_number, ssn)
    access_token = authenticate

    uri = URI.parse "#{@@athenanet_base_url}/preview1/1959002/patients/bestsearch"
    parameters = {"firstname" => first_name, "lastname" => last_name}
    # try to put the dob in the correct format
    # no good way to handle european format at this point
    parameters["dob"] = date_of_birth.gsub('-','/')
    parameters["ssn"] = ssn.delete("^0-9") if ssn
    parameters["anyphone"] = phone_number.delete("^0-9") if phone_number
    uri.query = URI.encode_www_form( parameters )
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true;
    request = Net::HTTP::Get.new(uri.path + '?' + uri.query.to_s)
    request.add_field("Authorization", "Bearer #{access_token}")
    request['Accept'] = 'application/json'
    response = http.request(request)
    # response.code
    data = JSON.parse response.body
  end

  def self.import_patient_emr_data(current_account, lifesquare_patient, athena_patient_id)
    athena_patient = get_patient(athena_patient_id)
    department_id = athena_patient['primarydepartmentid']
    athena_patient_ccda = download_patient_ccda(athena_patient_id, department_id)
    Ccda.import_emr_data(current_account, lifesquare_patient, athena_patient_ccda)
  end

  def self.get_patient(patient_id)
    access_token = authenticate
    uri = URI.parse "#{@@athenanet_base_url}/preview1/1959002/patients/#{patient_id}"
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true;
    request = Net::HTTP::Get.new(uri.path + '?' + uri.query.to_s)
    request.add_field("Authorization", "Bearer #{access_token}")
    request['Accept'] = 'application/json'
    response = http.request(request)
    # response.code
    # should only be one record so get rid of the array
    data = (JSON.parse response.body).first
  end

  def self.download_patient_ccda(patient_id, department_id)
    access_token = authenticate
    uri = URI.parse "#{@@athenanet_base_url}/preview1/1959002/patients/#{patient_id}/ccda"
    parameters = {"departmentid" => department_id, "purpose" => "internal"}
    uri.query = URI.encode_www_form( parameters )
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true;
    request = Net::HTTP::Get.new(uri.path + '?' + uri.query.to_s)
    request.add_field("Authorization", "Bearer #{access_token}")
    request['Accept'] = 'application/xml'
    response = http.request(request)
    # response.code
    data = response.body
  end

end
