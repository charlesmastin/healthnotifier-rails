class DocumentDigitized < ApplicationRecord
  self.sequence_name = :document_digitized_document_digitized_id_seq
  # attr_accessible :category, :title, :description
  has_many :document_digitized_files, -> { order(part_number: :asc) }

  def uid
    require "base64"
    return Base64.urlsafe_encode64(String(self.document_digitized_id))
  end

end
