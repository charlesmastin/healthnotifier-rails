class DocumentsController < ApplicationController
  before_action :authenticate_account!

  def show

    # monkey patch some bits
    auth_account = current_account

    # not check ownership for permission
    # note: not an acutal UUID

    # TODO: lookup canonical 404 throwing son

    begin
      id = Base64.urlsafe_decode64(params[:uuid])
    rescue
      render text: "Not Found", status: 404
      return
    end
    # TODO: auth check on this bizzle? this is relatively insecure
    @dd = DocumentDigitized.where(:document_digitized_id => id).first

    if @dd == nil
      render text: "Not Found", status: 404
      return
    end

    @baseurl = request.protocol + request.host_with_port
    @controls = true
    @pha = PatientHealthAttribute.where(:document_digitized_id => id ).first
    @privacy_options = Values.call('privacy')
    @owner = false
    @patient = Patient.where(:account_id => auth_account.account_id).first
    @owner_patient = Patient.where(:patient_id => @pha.patient_id).first
    if @owner_patient.account_id == auth_account.account_id
      @owner = true
    else
      unless view_permission_for_account_to_patient_item(auth_account.account_id, @pha.patient_id, @pha.privacy)
        render text: "Permission Denied", status: 403
      end
    end
  end

end