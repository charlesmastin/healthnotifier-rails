class Invoice < ApplicationRecord
    belongs_to :payment
    # TODO: this is temporarily fixing things
    belongs_to :organization
end