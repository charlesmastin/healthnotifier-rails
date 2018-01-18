class CarePlan < ApplicationRecord

  enum status: {
    draft: 'DRAFT',
    active: 'ACTIVE',
    deleted: 'DELETED'
  }

  # Aliases
  alias_attribute :question_groups, :care_plan_question_groups
  alias_attribute :recommendations, :care_plan_recommendations
  # Associations
  #has_one :organization
  belongs_to :organization
  has_many :care_plan_question_groups, -> { order(position: :asc) }, dependent: :destroy
  has_many :care_plan_recommendations, dependent: :destroy
  has_many :care_plan_responses

  self.sequence_name= :care_plan_care_plan_id_seq

  def question_group(question_group_uuid)
    # TODO: test performance vs running query to load question group
    # QuestionGroup.where({id: question_group_id, care_plan_id: care_plan_id})
    self.question_groups.find { |question_group| question_group.uuid == question_group_uuid }
  end

  def next_question_group(question_group_uuid)
    # XXX: this is def gonna be nil in the case of not having more than 1 question groups
    # primarily a case of clientside validation fail and bad data entry on the editor
    # assuming no choice was mapping to a recommendation
    next_question_group = nil
    index = self.question_groups.find_index { |question_group| question_group.uuid == question_group_uuid }
    next_question_group = self.question_groups[index+1]
    next_question_group
  end

  def recommendation(recommendation_uuid)
    self.recommendations.find { |recommendation| recommendation.uuid == recommendation_uuid }
  end

  def slug
    self.name
  end

  def as_json(options = { })
    # TODO: @jerry unsure of why we get mad beef when calling the self.next_question_group(nil) helper
    if self.question_groups[0] != nil
      super(options).merge({:initial_question_group_uuid => self.question_groups[0].uuid})
    end
  end

  def self.from_editor_json(json)
    # persist a new care plan and all the goodies
    # TODO: deal with deactivation of old plan / updates etc, blablabla
    # TODO: concept of plan drafts, etc
    care_plan = nil
    CarePlan.transaction do
      care_plan = CarePlan.find_by(uuid: json[:uuid]) if json[:uuid]
      if care_plan.nil?
        # new care plan. create it
        care_plan = CarePlan.create(
          :name => json[:name],
          :status => json[:status],
          :organization_id => json[:organization_id],
          :description => '', # muahahaha
          :filters => nil
        )
      else
        # perform the updates, lolzors (these are the only fields coming in son)
        care_plan.name = json[:name]
        care_plan.status = json[:status]
        care_plan.organization_id = json[:organization_id]
        care_plan.save!
      end

      # create/update all the recommendations
      # using a hash to store uuid -> recommendation so that database queries aren't required
      # especially since the recommendations may not have been saved yet
      recommendations_by_uuid = {}
      # XXX: http://stackoverflow.com/questions/14647731/rails-converts-empty-arrays-into-nils-in-params-of-the-request
      json[:recommendations].to_a.each do |json_recommendation|
        recommendation = care_plan.recommendations.find_by(uuid: json_recommendation[:uuid])
        if recommendation
          recommendation.name = json_recommendation[:name] || ''
          recommendation.text = json_recommendation[:components].to_json
          recommendation.save!
        else
          recommendation = care_plan.recommendations.create(
            :name => json_recommendation[:name] || '',
            :description => '',
            :text => json_recommendation[:components].to_json,
            :uuid => json_recommendation[:uuid]
          )
        end
        recommendations_by_uuid[recommendation.uuid] = recommendation
      end

      # create/update all the question groups
      # using a hash to store uuid -> question group so that database queries aren't required
      # especially since the question groups may not have been saved yet
      question_groups_by_uuid = {}
      json[:groups].to_a.each_with_index do |json_group, group_index|
        question_group = care_plan.question_groups.find_by(uuid: json_group[:uuid])
        if question_group
          question_group.name = json_group[:name] || ''
          question_group.description = json_group[:description]
          question_group.save!
        else
          question_group = care_plan.question_groups.create(
            :name => json_group[:name] || '',
            :description => json_group[:description],
            :uuid => json_group[:uuid]
          )
        end
        question_group.set_list_position(group_index+1)
        question_group.save!
        question_groups_by_uuid[question_group.uuid] = question_group
      end

      # iterate through the question groups and process the questions and choices
      json[:groups].to_a.each do |json_group|
        question_group = question_groups_by_uuid[json_group[:uuid]]
        json_group[:questions].to_a.each_with_index do |json_question, question_index|
          question = question_group.questions.find_by(uuid: json_question[:uuid])
          if question
            question.name = json_question[:name]
            question.description = json_question[:description]
            question.choice_type = json_question[:choice_type]
          else
            question = question_group.questions.create(
              :name => json_question[:name],
              :description => json_question[:description],
              :choice_type => json_question[:choice_type],
              :uuid => json_question[:uuid]
              # default input_type, because we just don't care
            )
          end
          question.set_list_position(question_index+1)
          question.save!
          json_question[:choices].to_a.each_with_index do |json_choice, choice_index|
            question_choice = question.choices.find_by(uuid: json_choice[:uuid])
            if question_choice
              question_choice.name = json_choice[:name]
            else
              question_choice = question.choices.create(
                :name => json_choice[:name],
                :uuid => json_choice[:uuid]
                # description
                # text
              )
            end
            trigger_uuid = nil
            trigger_uuid = json_choice[:trigger][:uuid] if json_choice[:trigger]
            # always assign to both to make things get set to nil if previous values existed
            question_choice.next_recommendation = recommendations_by_uuid[trigger_uuid]
            question_choice.next_question_group = question_groups_by_uuid[trigger_uuid]
            question_choice.set_list_position(choice_index+1)
            question_choice.save!
          end
          # delete choices not found in the json
          question_choices_to_delete = question.choices.map {|qc| qc.uuid} - json_question[:choices].to_a.map {|qc| qc[:uuid]}
          question_choices_to_delete.each {|uuid| question.choices.find_by(uuid: uuid).destroy!}
        end
        # delete questions not found in the json
        questions_to_delete = question_group.questions.map {|q| q.uuid} - json_group[:questions].to_a.map {|q| q[:uuid]}
        questions_to_delete.each {|uuid| question_group.questions.find_by(uuid: uuid).destroy!}
      end
      # delete recommendations not found in the json
      recommendations_to_delete = care_plan.recommendations.map {|r| r.uuid} - recommendations_by_uuid.keys
      recommendations_to_delete.each {|uuid| care_plan.recommendations.find_by(uuid: uuid).destroy!}
      # delete question groups not found in the json
      question_groups_to_delete = care_plan.question_groups.map {|qg| qg.uuid} - question_groups_by_uuid.keys
      question_groups_to_delete.each {|uuid| care_plan.question_groups.find_by(uuid: uuid).destroy!}
    end
    care_plan

  end

  def to_editor_json
    # this is the custom to_json as we need it for our react editor and super light weight syntax
    # {
    #   name: 'A new plan design™',
    #   organization_id: 3,
    #   groups:[
    #       {
    #         id: 0,
    #         name: null,
    #         description: null,
    #         questions: [q1]
    #       },
    #       {
    #         id: 1,
    #         name: null,
    #         description: null,
    #         questions: [q2, q3]
    #       },
    #       {
    #         id: 2,
    #         name: null,
    #         description: null,
    #         questions: [q4]
    #       }
    #   ],
    #   recommendation: {
    #     text: 'Blablablabla blabla'
    #   }
    # }
    recommendations_node = []
    self.recommendations.each do |recommendation|
      recommendations_node.push(recommendation.to_json)
    end
    # groups up in the bizzle
    groups_node = []
    self.question_groups.each do |group|
      groups_node.push(group.to_json)
    end

    {
      :uuid => self.uuid,
      :name => self.name,
      :status => self[:status],
      :organization_id => self.organization_id,
      :groups => groups_node,
      :recommendations => recommendations_node
    }
  end

end
