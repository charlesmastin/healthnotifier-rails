class ProviderCredential < ApplicationRecord

  # this entire class should be considering the existing and potentially overlapping state of creds, lol

  self.primary_key = :provider_credential_id
  belongs_to :patient, inverse_of: :provider_credentials
  belongs_to :document_digitized

  enum status: {
    accepted: 'ACCEPTED',
    expired: 'EXPIRED',
    pending: 'PENDING',
    rejected: 'REJECTED'
  }

  validates :status, :presence => true
  after_initialize do
    self[:status] = 'PENDING' unless self[:status].present?
  end
  after_save do
    account = patient.account
    account.establish_provider self.accepted?
  end

  def past_expiration?
    Date.today >= expiration
  end
end
