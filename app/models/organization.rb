class Organization < ApplicationRecord
  # attr_accessible :title, :body
  has_many :campaigns
  has_many :care_plans
  has_many :invoices
  
  def get_contact_name
      return "#{self.salutation} #{self.first_name} #{self.last_name}"
  end
  
  def get_contact_email
      return self.contact_email
  end
  
  def get_coverage_cost
    cost = Rails.configuration.default_coverage_cost
    # TODO: custom lower cost baked in during customer support provisioning
  end

  def get_membership_count
    total = 0
    total = self.get_patients.length
    total

    # # aka, covered, sponsored, etc
    # # not to be confused with the owners and hr managers, etc
    # total = 0
    # # TODO: sort out which are in fact active and covered blablabla, and not expired, or whatnot

    # self.campaigns.each do |campaign|
    #   # TODO: LOGIC UP IN DIS BIT SON
    #   campaign.lifesquares.each do |lifesquare|
    #     if lifesquare.patient
    #       # patients.append(lifesquare.patient)
    #       total += 1
    #     end
    #   end
    #   # total += campaign.lifesquares.count
    # end

    # total
  end

  def get_patients
    patients = []
    self.campaigns.each do |campaign|
      campaign.lifesquares.each do |lifesquare|
        if lifesquare.patient
          patients.append(lifesquare.patient)
        end
      end
    end
    patients
  end

  def get_unit_cost
    # tap the DB son, with a migration to get the current standard coverage rate though
    2000
  end

  def to_json_public
    return {
      :uuid => self.uuid,
      :name => self.name,
    }
  end
  
end
