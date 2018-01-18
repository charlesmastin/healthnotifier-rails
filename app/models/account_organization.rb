class AccountOrganization < ApplicationRecord

  enum status: {
    active: 'ACTIVE',
    deleted: 'DELETED'
  }

  enum role: {
    owner: 'OWNER', # 
    admin: 'ADMIN', #
    member: 'MEMBER' #
  }

  # do I need this?
  self.sequence_name= :account_organization_account_organization_id_seq

  # meh meh meh
  belongs_to :organization
  belongs_to :account

end