# BLOW THIS UP IN A FIRE AT SOME POINT
# BURN IT DOWN
# SMASH IT TO PIECES
# REBUILD IT FROM THE ASHES IN A SERVICE

require 'open3'
require 'rubygems'

class QrcodeController < ApplicationController

  before_action :authenticate_account!
  before_action :require_lifesquare_employee

  ACTION_VALUE_IS_NOT_SET = 0
  ACTION_VALUE_IS_VALID   = 1
  ACTION_VALUE_IS_INVALID = 2

  ########################################################################
  #
  # Get a code that can be assigned to a new user that does not
  # already have one.
  #
  # Pre :
  #       patient_id is a valid, pre-checked , patient id
  #
  # Post :
  #       A unique lifesquare code will have been created and stored
  #       The code will have been made active
  #       The code will have been assigned to the patient
  #       If requested a request for a sheet of printed lifesquares codes will have been added
  #
  # add_a_request : add sheet request to queue
  # patient_id    : the patient who will own this id
  # address       : hash that contains  :address_line1 :address_line2 :address_line3
  #                                     :city :state_province :country :postal_code
  #
  ########################################################################
  WEBSITE_REQUESTOR_ID = 5
  WEBSITE_BATCH_ID = -2
  DEFAULT_PRIORITY = 0
  
  def self.get_assignable_code(add_a_request, patient_id, address)
    lifesquare = Lifesquare.new do |obj|
      obj.lifesquare_uid = Lifesquare.generate_code
      obj.create_user = WEBSITE_REQUESTOR_ID
      obj.update_user = WEBSITE_REQUESTOR_ID
      obj.valid_state = 1 # aka lifesquare.VALID
      obj.patient_id = patient_id
      obj.activation_date = DateTime.now
    end

    count = 0
    is_saved = false

    # this is an attempt at avoiding collisions, since the static generator has now awareness of existing codes
    until (count==3)||is_saved==true
      is_saved = (lifesquare.save) != 0
      count +=1
    end

    # TODO: Decouple this extract to another flow
    if is_saved
      if add_a_request
       CodeSheetPrintRequest.add_new_request(lifesquare.lifesquare_uid, address, DEFAULT_PRIORITY)
      end
      return lifesquare.lifesquare_uid
    end

    nil
  end

  ########################################################################
  #
  #   List al the campaigns and the number of accecpted LSCs
  #
  ########################################################################
  def campaigns

    @campaigns =  Campaign.all

    @info = []

    @campaigns.each do |campaign|
      item = {}
      item[:id]   = campaign.campaign_id
      item[:name] = campaign.name
      item[:count] = Lifesquare.where(campaign_id: campaign.campaign_id).count
      @info.push item
    end
  end

  ERROR_CODE_NO_ERROR_CODE = 0
  ERROR_MSG_NO_ERROR_CODE = "No error"
  ERROR_CODE_UNKNOWN_CODE = -999
  ERROR_MSG_UNKNOWN_CODE = "This code does not exist on system"
  ERROR_CODE_ALREADY_SET = -998
  ERROR_MSG_ALREADY_SET =  "This code has already been set. Duplicate?"
  ERROR_CODE_INVALID_ACTION_ID = -997
  ERROR_MSG_INVALID_ACTION_ID =  "ERROR_MSG_INVALID_ACTION_ID"
  ERROR_CODE_INVALID_CAMPAIGN_ID = -996
  ERROR_MSG_INVALID_CAMPAIGN_ID = "Uknown campaign id"

  ACTION_ID_SET_AS_VALID = 0
  ACTION_ID_SET_AS_INVALID = 1
  ACTION_ID_UNSET = 2


  

  def show_batch_details
    
  end

private

  def collect_batch_details(batch_id)
    item = {}

    matching = Lifesquare.where(batch_id: batch_id)

    matching_count = matching.count

    item[:id] = batch_id
    item[:count] = matching_count

    unset    = Lifesquare.where(:batch_id => batch_id,:valid_state => 0 ).count
    accepted = Lifesquare.where(:batch_id => batch_id,:valid_state => 1 ).count
    rejected = Lifesquare.where(:batch_id => batch_id,:valid_state => 2 ).count

    item[:unset]    = unset
    item[:accepted] = accepted
    item[:rejected] = rejected

    item
  end

end
