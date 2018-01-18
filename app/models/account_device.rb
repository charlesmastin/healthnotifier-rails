class AccountDevice < ApplicationRecord
  self.sequence_name= :account_device_account_device_id_seq
  belongs_to :account, optional: true

  before_create :set_uuid

  def set_uuid
    self.uuid = SecureRandom.uuid
  end
end