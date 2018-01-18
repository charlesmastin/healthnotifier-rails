class ImoMedGenericName < ApplicationRecord
  self.primary_keys = [:med_name, :generic_name]

  alias_attribute :name, :generic_name

  # Table relationships


  # Validations
  
end
