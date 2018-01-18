class CarePlanQuestionGroup < ApplicationRecord

  enum status: {
    active: 'ACTIVE',
    deleted: 'DELETED'
  }

  # Aliases
  alias_attribute :questions, :care_plan_questions
  # Associations
  belongs_to :care_plan
  acts_as_list scope: :care_plan
  has_many :care_plan_questions, -> { order(position: :asc) }, dependent: :destroy

  self.sequence_name= :care_plan_question_group_care_plan_question_group_id_seq

  def question(question_uuid)
    self.questions.find { |question| question.uuid == question_uuid }
  end

  # OVERRIDE HAHAHAHA
  def to_json
    questions_node = []
    self.questions.each do |question|
      questions_node.push(question.to_json)
    end
    {
      :care_plan_uuid => self.care_plan.uuid,
      :uuid => self.uuid,
      :name => self.name,
      :description => self.description,
      :questions => questions_node
    }
  end

end
