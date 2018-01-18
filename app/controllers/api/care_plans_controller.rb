module Api
  class CarePlansController < Api::ApplicationController
    before_action :authenticate_account
    before_action :require_lifesquare_employee
    before_action :establish_patient

    # answer processor
    def process_response
      @question_group = CarePlanQuestionGroup.where(:uuid => params[:question_group_uuid]).first
      @care_plan = @question_group.care_plan

      session_id = session.id
      if session_id == nil
        # mobile auth context blablabla
        # make up a sesssion for now
        # let's see, a hashed version of the account.auth_token and the mm/dd/yyyy so you get one mobile "session" per day
        # and lol base64 that shee for fun

        begin
          session_id = Base64.encode64(@patient.uuid + "-" + DateTime.now.strftime("%F"))
        rescue
          session_id = @account.get_account_token
        end
      end

      next_action = CarePlanProcessor.next_action(
        session_id,
        @patient,
        @care_plan,
        question_group_uuid=params[:question_group_uuid],
        question_uuids=params[:answers].map { |item| item[:question_uuid] },
        choice_uuids=params[:answers].map { |item| item[:choice_uuid] }
      )
      # switch on the type of next_action
      # issue some JSON back to the client
      # client will probably redirect
      if next_action != nil
        if next_action.is_a?(CarePlanQuestionGroup)
          render json: {
            :success => true,
            :message => "Responses have been recorded",
            :redirect_url => care_plans_question_group_url(@patient.uuid, @care_plan.uuid, next_action.uuid), # for legacy web client
            :question_group_uuid => next_action.uuid,
            :care_plan_uuid => @care_plan.uuid,
            :complete => false
          }, status: 200
          return
        end
        if next_action.is_a?(CarePlanRecommendation)
          render json: {
            :success => true,
            :message => "All responses have been recorded",
            :redirect_url => care_plans_advice_url(@patient.uuid, @care_plan.uuid, next_action.uuid), # for legacy web client
            :recommendation_uuid => next_action.uuid,
            :care_plan_uuid => @care_plan.uuid,
            :complete => true
          }, status: 200
        end
      else
        # we failed to determine
        render json: {
          :success => false,
          :message => "Something went wrong :("
        }, status: 500
      end
    end

    def index
      # TODO: error handle nugget nutts
      @care_plans = CarePlanProcessor::get_patient_care_plans(@patient.patient_id)
      # don't do the custom to_json yet son
      render json: @care_plans.to_json, status: 200
    end

    def question_group
      # XXX: this 'exposes' the triggers since it uses the common serializer blablabla, not a big deal though, something fun for someone monitoring packets I suppose
      @question_group = CarePlanQuestionGroup.where(:uuid => params[:question_group_uuid]).first
      render json: @question_group.to_json, status: 200
    end

    def recommendation_show
      # XXX: MEMEMEMEMEEMEMEHEHEHEHE
      @recommendation = CarePlanRecommendation.where(:uuid => params[:recommendation_uuid]).first
      render json: @recommendation.to_json, status: 200
    end

  end
end
