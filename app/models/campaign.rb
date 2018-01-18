class Campaign < ApplicationRecord

  has_many :lifesquares

  # When a new campaign is created, one needs to create a new Stripe plan.  Then we need to
  # populate the

  self.sequence_name = :seq_campaign

  attr_readonly :campaign_id, :create_date, :create_user

  before_create :initialize_uuid

  def initialize_uuid
    self.uuid = SecureRandom.uuid if self.uuid.nil?
  end

  #set_date_columns :start_date, :end_date if respond_to?(:set_date_columns)

  # Table relationships
  # nullable due to legacy data
  belongs_to :organization
  has_many :lifesquares

  enum campaign_status: {
    ACTIVE: 1,
    INACTIVE: 0,
    EXPIRED: 2 
  }

  # Validations

  # TODO: when saving with a promo code, ensure it's unique
  
  validates :name, :length => {:maximum => 30},
    :presence => true

  validates :description, :length => {:maximum => 1000}
  validates :start_date, :presence => true

  # Requires the validates_timeliness library
  validates_date :start_date
  validates_date :end_date, :allow_nil => true, :allow_blank => true

  after_initialize do
    self[:start_date] ||= Time.now
    self[:renewal_date] ||= Time.now + 1.year
  end

  # admin and convenience methods bro
  def total_lifesquares_count
    self.lifesquares.count
  end

  def claimed_lifesquares_count
    self.lifesquares.where.not(patient_id: nil).count
  end

  def set_random_promo_code
    # random 6 alpha numeric bro
    self.promo_code = SecureRandom.uuid[0..5].upcase
  end

  def to_json_public
    return {
      :uuid => self.uuid,
      :requires_shipping => self.requires_shipping,
      :name => self.name,
      :pre_signup_memo => self.pre_signup_memo,
      :post_signup_memo => self.post_signup_memo,
      :description => self.description
    }
  end

end
