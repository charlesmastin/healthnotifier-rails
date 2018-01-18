class ScannerType < ApplicationRecord
  self.primary_key = :scanner_type

  alias_attribute :name, :user_mask

  attr_readonly :scanner_type

  # Table relationships


  # Validations
  validates :scanner_type, :length => {:maximum => 10},
    :presence => true

  validates :user_mask, :length => {:maximum => 50},
    :presence => true


end
