class CarePlanQuestionChoice < ApplicationRecord

  enum status: {
    active: 'ACTIVE',
    deleted: 'DELETED'
  }

  attr_accessor :checked
  alias_attribute :question, :care_plan_question
  # Associations
  belongs_to :care_plan_question
  belongs_to :next_recommendation, class_name: "CarePlanRecommendation", foreign_key: "next_care_plan_recommendation_id"
  belongs_to :next_question_group, class_name: "CarePlanQuestionGroup", foreign_key: "next_care_plan_question_group_id"
  acts_as_list scope: :care_plan_question

  self.sequence_name= :care_plan_question_choice_care_plan_question_choice_id_seq

  def checked
    @checked || false
  end

end
