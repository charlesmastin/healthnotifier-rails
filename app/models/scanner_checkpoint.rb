class ScannerCheckpoint < ApplicationRecord
  # Bogus constraint because rails (activerecord) insists on a pk
  self.primary_keys = [:steward_scanner_patient_log_id, :create_date]

  # Table relationships


  # Validations
  
end
