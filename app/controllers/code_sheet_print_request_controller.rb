
require 'open3'

class CodeSheetPrintRequestController < ApplicationController

  # before_filter :require_admin_user
  before_action :authenticate_account!
  before_action :require_lifesquare_employee

  # OMG SON, enum this beast already INTO THE MODEL YOU SLUT
  STATUS_NEW            = 0
  STATUS_SPECCED        = 1
  STATUS_VERIFIED_GOOD  = 2
  STATUS_VERIFIED_BAD   = 3
  STATUS_MAILED         = 4
  STATUS_UNKNOWN_PATIENT= 6

  ACTION_ID_ACCEPT = 0
  ACTION_ID_REJECT = 1

  ERROR_CODE_NO_ERROR_CODE = 0
  ERROR_MSG_NO_ERROR_CODE = "No error"
  ERROR_CODE_UNKNOWN_CODE = -899
  ERROR_MSG_UNKNOWN_CODE = "This request does not exist on system"
  ERROR_CODE_ALREADY_SET = -898
  ERROR_MSG_ALREADY_SET =  "This request has already been set."
  ERROR_CODE_INVALID_ACTION_ID = -897
  ERROR_MSG_INVALID_ACTION_ID =  "ERROR_MSG_INVALID_ACTION_ID"

  def self.set_code_sheet_status(action, code)
    action = action - 3

    response = {}
    response[:error_code] = ERROR_CODE_NO_ERROR_CODE
    response[:error_msg] = ERROR_MSG_NO_ERROR_CODE

    if CodeSheetPrintRequest.request_exists?(code)
      if CodeSheetPrintRequest.request_already_processed?(code)
        response[:error_code] = ERROR_CODE_ALREADY_SET
        response[:error_msg] = ERROR_MSG_ALREADY_SET
        return response
      end
      case action
        when ACTION_ID_ACCEPT
          CodeSheetPrintRequest.sheet_request_accepted(code)
        when ACTION_ID_REJECT
          CodeSheetPrintRequest.sheet_request_rejected(code)
        else
          response[:error_code] = ERROR_CODE_INVALID_ACTION_ID
          response[:error_msg] = ERROR_MSG_INVALID_ACTION_ID
      end
    else
      response[:error_code] = ERROR_CODE_UNKNOWN_CODE
      response[:error_msg] = ERROR_MSG_UNKNOWN_CODE
    end
    response
  end



  # Add a new request - this is basically a show and tell dev function for testing doesn't need to exist
  # REMOVE after adding rspec coverage
  def add
    if request.get?
      # returns the form from the template
    else
      lifesquare_uid = params[:lsc]
      priority = params[:priority].to_i
      address = {
        :address_line1 => "50 Hawthorne St.",
        :address_line2 => "",
        :city => "San Francisco",
        :state_province => "CA",
        :postal_code => "94105"
      }
      result = CodeSheetPrintRequest.add_new_request(lifesquare_uid, address, priority)
      flash[:error] = "Done"
      render :add
    end
  end

  def generate
    if request.get?
      # a get form
      @outstanding_request_reprint_count = CodeSheetPrintRequest.where(:status => STATUS_NEW, :reprint => true).count
      @outstanding_request_new_count = CodeSheetPrintRequest.where(:status => STATUS_NEW, :reprint => false).count
      @outstanding_request_count = @outstanding_request_reprint_count + @outstanding_request_new_count
    else
      @outstanding_request_count = CodeSheetPrintRequest.where(:status => STATUS_NEW).count
    end
  end

end
