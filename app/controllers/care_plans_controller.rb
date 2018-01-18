class CarePlansController < ApplicationController
    before_action :authenticate_account!
    before_action :require_lifesquare_employee
    before_action :obtain_patient, :except => [:index]
    before_action :obtain_care_plan, :only => [:care_plan, :question_group, :process_question_group, :advice]
    before_action :obtain_question_group, :only => [:question_group, :process_question_group]

    def index
        return unless account_patients
    end

    def patient_show
        # narrow down your conditions son
        @care_plans = CarePlanProcessor::get_patient_care_plans(@patient.patient_id)
    end

    def care_plan
        # aka the landing and entry point
    end

    def question_group
        # ghetto calculate next
        @next = nil
        @care_plan.question_groups.each_with_index do |qg, index|
            # hack it in there slim jim
            if @question_group == qg && index < @care_plan.question_groups.length - 1
                @next = @care_plan.question_groups[index+1]
            end
        end
    end

    def advice
        # yea son, get dat recommendation
        @recommendation = CarePlanRecommendation.where(:uuid => params[:recommendation_uuid]).first
        if @recommendation == nil
            
        end
    end

private

    def obtain_care_plan
        # TODO: for good measure obtain or list first, to be sure we "qualify" for the plan
        @care_plan = CarePlan.where(:uuid => params[:care_plan_uuid]).first

        # conditions.each do |c|
        #     if c[:slug] == params[:condition]
        #         @condition = c
        #         break
        #     end
        # end
        if @care_plan == nil
            redirect_to patient_index_path
            return 
        end
    end

    def obtain_question_group
        @question_group = CarePlanQuestionGroup.where(:uuid => params[:question_group_uuid]).first
    end

end