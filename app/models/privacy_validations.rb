module PrivacyValidations
  extend ActiveSupport::Concern

  included do
    validates_inclusion_of :privacy, :in => Values.call('privacy').collect { |item| item[:value] }
  end
end