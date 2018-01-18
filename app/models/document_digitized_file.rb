class DocumentDigitizedFile < ApplicationRecord

  self.sequence_name = :document_digitized_file_document_digitized_file_id_seq
  # attr_accessible :part_number, :file_format, :file_spec, :digitized_file_uid
  belongs_to :document_digitized

  def generate_remote_path
    return "document-digitized-files/#{document_digitized.id}/#{part_number}_#{file_spec}"
  end

  def uid
    require "base64"
    return Base64.urlsafe_encode64(self.digitized_file_uid)
  end

  def file_spec_source=(local_file_spec)
    self.digitized_file = local_file_spec.blank? ?
      nil : File.new(local_file_spec)
  end
end
