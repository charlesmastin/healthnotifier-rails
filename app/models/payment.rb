class Payment < ApplicationRecord
  # attr_accessible :title, :body
  
  # Associations
  has_many :coverages
  has_many :patients
  has_many :invoices
end
