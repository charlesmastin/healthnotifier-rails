require 'date'

module CarePlanProcessor

  def self.get_patient_care_plans(patient_id)
    # load all global care plans (those without an organization)
    # TODO: blablablabalbala query with rails4 enums, blablablablabal
    # PRODUCT DEMO DAYS SON, allow all status except deleted through, disambiguate on the iteraction for employees to test DRAFTS SON
    global_care_plans = CarePlan.where({:organization_id => Rails.application.config.default_organization_id})
    patient = Patient.find(patient_id)
    # override the global care plans with organization care plans where possible
    care_plans_by_name = {}
    global_care_plans.each { |cp| care_plans_by_name[cp.name] = cp }
    org_care_plans = CarePlan.where({:organization_id => patient.organization.id}) if patient.organization
    org_care_plans.each { |cp| care_plans_by_name[cp.name] = cp } if org_care_plans
    care_plans = care_plans_by_name.values
    # filter the care plans based on the patient attributes
    # TODO: move this logic into CarePlan or Patient
    care_plans.select! { |care_plan| CarePlanFilter::match?(care_plan, patient) }
    # only show active care plans to non-lifesquare accounts
    # TODO: push this into the filter match or use separate APIs for admin vs patient
    care_plans.select! { |care_plan| care_plan.active? } unless patient.account.lifesquare_employee?
    care_plans
  end

  def self.next_action_with_ids(session_id, patient_id, care_plan_uuid, question_group_uuid=nil, question_uuids=[], choice_uuids=[])
    patient = Patient.find(patient_id)
    care_plan = CarePlan.where(:uuid => care_plan_uuid).first
    next_action(session_id, patient, care_plan, question_group_uuid, question_uuids, choice_uuids)
  end

  def self.next_action(session_id, patient, care_plan, question_group_uuid=nil, question_uuids=[], choice_uuids=[])
    next_action = nil
    # if the question group id is nil, assume this is the initial call
    if question_group_uuid.nil?
      next_action = care_plan.question_groups.first
    else
      # load the current question group
      question_group = care_plan.question_group(question_group_uuid)
      # for each question, determine whether the next action is a question group or recommendation
      question_uuids.each_with_index do |question_uuid, index|
        question = question_group.question(question_uuid)
        # TODO: handle multi-answer. no examples yet, so I'm not sure what it will look like
        choice = question.choice(choice_uuids[index])
        # if a recommendation is found, break out of the loop
        if choice.next_recommendation
          # TODO: should this be encapsulated in CarePlanQuestionChoice?
          next_action = choice.next_recommendation
          break
        else
          # TODO: possibly try to be smart and make sure to use the first group by position
          next_action = choice.next_question_group
          # if a question_group is found, keep going in case there is a recommendation
        end
      end
      # TODO: revisit
      # if no next_action was found, default to using the next question_group
      next_action = care_plan.next_question_group(question_group_uuid) if next_action.nil?
      # for a question group, try to pre-select responses if possible
      preselect_question_group_choices(session_id, next_action) if next_action.is_a? CarePlanQuestionGroup
    end
    # record patient responses
    record_responses(session_id, care_plan, patient, question_group, question_uuids, choice_uuids, next_action)
    next_action
  end

  def self.preselect_question_group_choices(session_id, question_group)
    question_group.questions.each {|question| preselect_question_choices(question) } if question_group
  end

  def self.preselect_question_choices(question)
    # evaluate each response to see if it should be selected by default
    # stop at the first one that evaluates to true so we never have more than one set as selected
    # (shouldn't happen, but difficult to enforce)
  end

  def self.record_responses(session_id, care_plan, patient, question_group, question_uuids, choice_uuids, next_action)
    CarePlanResponse.add_question_group_responses(session_id, care_plan, patient, question_group, question_uuids, choice_uuids, next_action)
  end

end
