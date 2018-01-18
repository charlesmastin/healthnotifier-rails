class CarePlanRecommendation < ApplicationRecord

  enum status: {
    active: 'ACTIVE',
    deleted: 'DELETED'
  }

  # Associations
  belongs_to :care_plan

  self.sequence_name= :care_plan_recommendation_care_plan_recommendation_id_seq

  # Findings
  # Treatment
  # Precautions
  # Work Restrictions
  # School Restrictions (for Pediatric plans)
  # Travel Restrictions
  # Dietary Suggestions
  # Follow Up

  # The Plan Will Have a default recommendation

  def components
    begin
      JSON.parse(self.text)
    rescue
      []
    end
  end

  def to_json
    {
      :uuid => self.uuid,
      # :text => self.text,
      :description => self.description,
      :name => self.name,
      :components => self.components
    }
  end

end