class AccountToken < ApplicationRecord
    belongs_to :account
    belongs_to :account_device, optional: true

    # SecureRandom.urlsafe_base64(15).tr('lIO0', 'sxyz')
    # SecureRandom.uuid

    # # Temporary Auth table to manage expirable tokens while we move everything to OAuth2
    # we must make this basically behave like the legacy one token per account for now
    # aka if no account_device_id is present, this is a one token per device behavior, yea son
    # point of no return, but changing client data flow is too complex at this point
    # if might be simpler to just add an token_expiration to the account table for now, but this sets us up for the future
    # or is it silly and half-baked?

end