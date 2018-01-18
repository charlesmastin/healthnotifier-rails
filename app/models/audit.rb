class Audit < ApplicationRecord
    # TODO: this is getting the chop in favor of a more streamlined logging
    belongs_to :account, class_name: 'Account', foreign_key: 'scanner_account_id', optional: true

    def as_json(options = { })
    # we need the name, and healthcare provider status of each relationship, just for giggle
    # will this bomb on an defunt relationship, probably, so protect this house somehow

    super(options).merge({
        :scanner_name => (self.account ? self.account.this_is_me_maybe.name : nil),
        :title => '',
        :description => ''
    })
  end
end