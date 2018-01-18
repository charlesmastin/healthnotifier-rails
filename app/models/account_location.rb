class AccountLocation < ApplicationRecord
  self.sequence_name= :account_location_account_location_id_seq
  belongs_to :account, optional: true
end