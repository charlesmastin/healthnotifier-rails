#require 'Location'

class CodeSheetPrintRequest < ApplicationRecord

  REQUEST_STATE_NEW = 0
  REQUEST_STATE_SPEECED = 1
  REQUEST_STATE_ACCEPTED = 2
  REQUEST_STATE_REJECTED = 3
  REQUEST_STATE_MAILED = 4

  self.sequence_name= :seq_lifesquare_send_task

  attr_readonly :code_sheet_print_request_id, :create_date, :create_user, :lifesquares, :address_line1, :city, :state_province, :country, :postal_code, :address_line2, :address_line3

  # Table relationships

  # Validations
  # the new CSV storage device son we have to support a "batch" for a collection transaction in the UI
  validates :lifesquares, :length => {:minimum => 9}, :presence => true

  validates :address_line1, :length => {:maximum => 150}

  validates :city, :length => {:maximum => 50}
  validates :state_province, :length => {:maximum => 50}
  validates :postal_code, :length => {:maximum => 15}
  validates :country, :length => {:maximum => 2}
  validates :address_line2, :length => {:maximum => 100}
  validates :address_line3, :length => {:maximum => 100}

  ##############################################################################
  # lifesquares   : CSV of lifesquare_uids SON
  # reprint vs new is irrelevant, but given the general access in the UI, only one or the other should exist for the "batch"
  # 
  # address       : hash that contains  :address_line1 :address_line2 :address_line3
  #                                     :city :state_province :country :postal_code
  #
  ##############################################################################
  def self.add_new_request(lifesquares, address=nil, priority=0)

    #obj = CodeSheetPrintRequest.most_recent_request(lifesquare_uid)
    #if obj && obj.status < REQUEST_STATE_ACCEPTED # the table ahs all requests - we only dups of codes that are complete
    #  return nil
    #end

    sheet_request = CodeSheetPrintRequest.new do |u|
      u.lifesquares = lifesquares
      u.priority = priority
      if address != nil
        u.address_line1 = address[:address_line1]
        u.address_line2 = address[:address_line2]
        u.address_line3 = address[:address_line3]
        u.city = address[:city]
        u.state_province = address[:state_province]
        u.country = address[:country]
        u.postal_code = address[:postal_code]
      end
    end

    sheet_request.save
    sheet_request.notify_admins
    sheet_request
  end

  def notify_admins
    # EMAIL IT NOW YEA SON
    email = Rails.application.config.default_print_admin_email
    subject = "New Print Request - #{self.id}"
    if !(validation_errors = ValidatesEmailFormatOf::validate_email_format(email))
      AccountMailer.send_email(email, subject, 'admin/mailer/new_print_request', {:object => self }).deliver_later
    end
  end

  def get_printable_address
    lines = []
    lines.push(address_line1.strip) if address_line1.present?
    lines.push(address_line2.strip) if address_line2.present?
    lines.push(address_line3.strip) if address_line3.present?
    s = ""
    s += city.strip if city.present?
    if state_province.present?
      s += ", " if city.present?
      s += state_province.strip
    end
    if postal_code.present?
      s += " " if city.present? or state_province.present?
      s += postal_code.strip
    end
    lines.push(s) if s.present?
    return lines.join("\n")
  end

  def get_s3_storage_path
    # this will work for now son
    "print-requests/#{self.code_sheet_print_request_id}.pdf"
  end

  def lifesquares_a
    self.lifesquares.split(',') # TODO: handle bad whitespace 
  end

  def self.sheet_request_accepted(lifesquare_uid)
    return self.set_new_state(lifesquare_uid, REQUEST_STATE_ACCEPTED)
  end

  def self.sheet_request_rejected(lifesquare_uid)
    return self.set_new_state(lifesquare_uid, REQUEST_STATE_REJECTED)
  end

  def self.set_new_state(lifesquare_uid, new_state)
    obj = CodeSheetPrintRequest.most_recent_request(lifesquare_uid)
    if obj
      #############################################
      case new_state
        when  REQUEST_STATE_NEW
          return false # this should NEVER be used to set into unspeeced state

        when REQUEST_STATE_SPEECED, REQUEST_STATE_ACCEPTED, REQUEST_STATE_MAILED
          obj.status = new_state

        when REQUEST_STATE_REJECTED # this state require new object added to list
          obj.status = REQUEST_STATE_REJECTED
          obj.save
          address = {
            :address_line1 => obj.address_line1,
            :address_line2 => obj.address_line2,
            :address_line3 => obj.address_line3,
            :city => obj.city,
            :state_province => obj.state_province,
            :country => obj.country,
            :postal_code => obj.postal_code
          }
          new_request = self.add_new_request( obj.lifesquare_uid, address, obj.priority+1)
        else
          return false

      end
      obj.save
    else
      return false
    end
    true
  end

  def self.request_exists?(lifesquare_uid)
    if CodeSheetPrintRequest.most_recent_request(lifesquare_uid)
      return true
    end
    return false
  end

  def self.request_already_processed?(lifesquare_uid)
    obj = CodeSheetPrintRequest.most_recent_request(lifesquare_uid)
    if obj
      case obj.status
        when REQUEST_STATE_NEW, REQUEST_STATE_SPEECED
          return false
        else
          return true
      end
    end
  end

  def self.most_recent_request(lifesquare_uid)
    # TODO: change this to a glob
    return nil
    return CodeSheetPrintRequest.order('created_at DESC').where(:lifesquare_uid => lifesquare_uid).first
  end

end
