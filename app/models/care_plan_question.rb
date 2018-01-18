class CarePlanQuestion < ApplicationRecord

  enum status: {
    active: 'ACTIVE',
    deleted: 'DELETED'
  }

  enum choice_type: {
    yes_no: 'YES_NO',
    single_answer: 'SINGLE_ANSWER',
    multi_answer: 'MULTI_ANSWER'
  }

  enum input_type: {
    radio: 'RADIO',
    checkbox: 'CHECKBOX'
  }

  # Aliases
  alias_attribute :question_group, :care_plan_question_group
  alias_attribute :choices, :care_plan_question_choices
  # Associations
  belongs_to :care_plan_question_group
  acts_as_list scope: :care_plan_question_group
  has_many :care_plan_question_choices, -> { order(position: :asc) }, dependent: :destroy

  self.sequence_name= :care_plan_question_care_plan_question_id_seq

  def choice(choice_uuid)
    self.choices.find { |choice| choice.uuid == choice_uuid }
  end

  # OVERRIDE SON
  # cry me a river
  def to_json
    # returns json
    # var q1 = {
    #     id: 0,
    #     name: 'Can you see colors?',
    #     description: null,
    #     choice_type: 'YES_NO',
    #     choices: [{
    #         name: 'Yes',
    #         trigger: {
    #             group: 2
    #         }
    #     },
    #     {
    #         name: 'No', // there is no particular reason to define this case in the editor, we should do it for them
    #         trigger: {
    #             group: 3
    #         }
    #     }
    #     ]
    # }
    choices_node = []
    self.choices.each do |choice|
      choice_node = {
        :name => choice.name,
        :uuid => choice.uuid
      }
      if choice.next_recommendation
        choice_node[:trigger] = {
          :type => 'recommendation',
          :uuid => choice.next_recommendation.uuid
        }
      end
      if choice.next_question_group
        choice_node[:trigger] = {
          :type => 'group',
          :uuid => choice.next_question_group.uuid
        }
      end
      choices_node.push(choice_node)
    end
    {
      :uuid => self.uuid,
      :name => self.name,
      :description => self.description,
      :choice_type => self[:choice_type],
      :choices => choices_node 
    }
  end

end
