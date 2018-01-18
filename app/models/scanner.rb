require 'securerandom'

class Scanner < ApplicationRecord
  self.primary_key = :scanner_uid

  attr_readonly :scanner_uid, :create_user, :create_date, :read_cnt_period_start, :read_cnt

  def before_create()
    self.scanner_uid = SecureRandom.uuid
  end

  def self.find_active(id)
    s = where(%[scanner_uid = ? AND account_status IN ('ACTIVE','CHECKIN','TEST','MONITOR')], id)
    s[0] if s.present?
  end

  # Table relationships

  belongs_to :account_status_assn, :class_name => 'AccountStatus', :foreign_key => :account_status, :primary_key => :account_status
  belongs_to :scanner_type_assn, :class_name => 'ScannerType', :foreign_key => :scanner_type, :primary_key => :scanner_type
  belongs_to :er_unit, :inverse_of => :scanners

  # For rails_admin
  alias_attribute :name, :scanner_uid

  # Validations
  validates :scanner_uid, :length => {:maximum => 50},
    :presence => true

  validates :er_unit_id, :presence => true

  validates :local_app_uid, :length => {:maximum => 20},
    :presence => true

  validates :account_status_assn, :presence => true
  validates :scanner_type_assn, :presence => true
  
  validates :notes, :length => {:maximum => 1000}

  validates :telephone_number, :length => {:maximum => 30}

  after_initialize do
    self[:account_status] ||= 'ACTIVE'
    self[:scanner_type] ||= 'IPHONE'
    self[:read_cnt] ||= 0
    self[:read_cnt_period_start] ||= Time.now
  end

end
