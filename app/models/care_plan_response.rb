class CarePlanResponse < ApplicationRecord

  enum status: {
    active: 'ACTIVE',
    deleted: 'DELETED'
  }

  before_create :initialize_uuid, :initialize_response_json

  self.sequence_name= :care_plan_response_care_plan_response_id_seq

  def initialize_uuid
    self.uuid = SecureRandom.uuid if self.uuid.nil?
  end

  def initialize_response_json
    if self.response.nil?
      response_hash = Hash.new
      response_hash['question_groups'] = Array.new
      response_hash['question_group_responses'] = Hash.new 
      self.response = response_hash
    end
  end

  def self.add_question_group_responses (session_id, care_plan, patient, question_group, question_uuids, choice_uuids, next_action)
    return unless question_group
    care_plan_response = CarePlanResponse.where(care_plan_id: care_plan.id, session_id: session_id).take
    if care_plan_response.nil?
      care_plan_json = care_plan.to_editor_json
      care_plan_response = CarePlanResponse.create(care_plan_id: care_plan.id, session_id: session_id, patient_id: patient.id, care_plan: care_plan_json)
    end

    question_group_uuid = question_group.uuid
    next_action_type = next_action.class.name.demodulize
    next_action_uuid = next_action.uuid
    # does this question group already exist?
    if !care_plan_response.question_groups.include?(question_group_uuid)
      # new question group, so add it. this is the common case.
      care_plan_response.question_groups << question_group_uuid
    else
      # if this question group exists, find out if the next action is the same
      # TODO: clean this up to use something other than strings
      existing_next_action_type = care_plan_response.question_group_response(question_group_uuid)['next_action_type']
      existing_next_action_uuid = care_plan_response.question_group_response(question_group_uuid)['next_action_uuid']
      if (existing_next_action_type != next_action_type) or (existing_next_action_uuid != next_action_uuid)
        # if the next action is different, do some state cleanup
        # if it was previously a recommendation, that can be ignored
        if next_action.is_a?(CarePlanQuestionGroup)
          index = care_plan_response.question_groups.index(existing_next_action_uuid)
          # delete the previous "next question group" and any after it
          care_plan_response.question_groups.slice!(index..-1) if index
        end
      end
    end
    question_group_response = care_plan_response.question_group_response(question_group_uuid)
    question_uuids.each_with_index do |question_uuid, index|
      # TODO: handle multi-answer. no examples yet, so I'm not sure what it will look like
      question = question_group.question(question_uuid)
      choice = question.choice(choice_uuids[index])
      question_group_response[question.uuid] = choice.uuid
    end
    question_group_response['next_action_type'] = next_action_type
    question_group_response['next_action_uuid'] = next_action_uuid
    care_plan_response.save
    care_plan_response.preselect_choices_from_previous_response(next_action, next_action_uuid)
  end

  def question_groups
    self.response['question_groups']
  end

  def question_group_responses
    self.response['question_group_responses']
  end

  def question_group_response(question_group_uuid)
    if !self.question_group_responses.key?(question_group_uuid)
      self.question_group_responses[question_group_uuid] = Hash.new
    end
    self.question_group_responses[question_group_uuid]
  end

  # if a question group response already exists for the next action
  # prepopulate the checked options, overriding any choices made based on expressions
  def preselect_choices_from_previous_response(next_action, next_action_uuid)
    question_group_response = question_group_response(next_action_uuid)
    if next_action.is_a?(CarePlanQuestionGroup) and question_group_response
      next_action.questions.each do |question|
        existing_choice_uuid = question_group_response[question.uuid]
        question.choices.each do |choice|
          choice.checked = (choice.uuid == existing_choice_uuid)
        end
      end
    end
  end

end
