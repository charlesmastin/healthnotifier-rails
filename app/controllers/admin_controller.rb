class AdminController < ApplicationController
  before_action :authenticate_account!
  before_action :require_lifesquare_employee

  DEFAULT_LIMIT = 10
  WillPaginate.per_page = 10

  layout 'admin'

  # COLD BREWED HOME BREWED SON - get your crud outta here, get your rails admin outta here, ok just mount them at a different location
  def index

  end

  # do some slick rick template loading up in this bizzle, for now, manually load it up SON

  # batches

  def batches_index
    # datagrid yourself silly, reinventing wheels since 1982™
    # batches = LifesquareCodeBatch.all.limit(DEFAULT_LIMIT).offset(params[:page] ? ((params[:page].to_i-1) * DEFAULT_LIMIT) : 0)
    @objects = LifesquareCodeBatch.paginate(:page => params[:page]).order("created_at DESC")
    # @collection_size = LifesquareCodeBatch.all.count
    # of course we start with the most annoying "annotated" record set, example, wtf man
    @annotated_objects = []
    @objects.each do |item|
      @annotated_objects.push(collect_batch_details item.id)
    end
    # fianlly all the unassigned ones
    # @batch_rows.push(collect_batch_details -1)
    render template: "admin/batches/index"
  end

  def batches_new
    @batch = LifesquareCodeBatch.new # meh, for the form ????
    @organizations = Organization.all.order(:name)
    render template: "admin/batches/new"
  end

  def batches_create
    # do the restful bs, then if we save, do the BOOYA KASAHA BUILD IT UP BOOOOiIII
    @batch = LifesquareCodeBatch.new(batch_params)
    if @batch.save
      printrequest = @batch.provision_lifesquares(current_account.account_id, params[:campaign_id], params[:sheets_per_lifesquare], params[:instructions])
      flash[:notice] = "Batch created! Now print it."
      redirect_to admin_batch_index_path
    else
      flash[:notice] = "There were errors creating your batch.<br />Something like… #{@batch.errors.full_messages}"
      redirect_to admin_batch_new_path
    end
  end

  def batches_show
    @batch = LifesquareCodeBatch.where(:lifesquare_code_batch_id => params[:id].to_i).first
    @codes = Lifesquare.where(batch_id: @batch.lifesquare_code_batch_id)
    render template: "admin/batches/show"
  end

  # campaigns

  def campaigns_index
    @objects = Campaign.paginate(:page => params[:page]).order("create_date DESC")
    render template: "admin/campaigns/index"
  end

  def campaigns_new
    @campaign = Campaign.new
    @plans = get_stripe_plans_for_select
    # get your manual lookups on, tedium 2 the max SON, don’t care though
    render template: "admin/campaigns/new"
  end

  def campaigns_edit
    @campaign = Campaign.where(:campaign_id => params[:id].to_i).first
    @plans = get_stripe_plans_for_select
    # get your manual lookups on, tedium 2 the max SON, don’t care though
    render template: "admin/campaigns/edit"
  end

  def campaigns_create
    @campaign = Campaign.new(campaign_params)
    # bum-rush the silly bits
    @campaign.create_user = current_account.account_id
    @campaign.update_user = current_account.account_id
    if @campaign.save
      flash[:notice] = "Campaign created! Now go <a href=\"#{admin_batch_new_path}\">cook up a batch of Lifesquares</a> or something useful."
      redirect_to admin_campaign_index_path
    else
      flash[:notice] = "There were errors creating your campaign.<br />Something like… #{@campaign.errors.full_messages}"
      redirect_to admin_campaign_new_path
    end
  end

  def campaigns_update
    @campaign = Campaign.find params[:id]
    @campaign.update_user = current_account.account_id
    if @campaign.update_attributes(campaign_params)
      flash[:notice] = "Campaign updated!"
      redirect_to admin_campaign_index_path
    else
      flash[:notice] = "There were errors saving your campaign"
      render :action => 'campaigns_edit'
    end
  end

  def campaigns_destroy
    @campaign = Campaign.find params[:id]
    @campaign.destroy
    flash[:notice] = "Campaign daaaaleeeted!"
    redirect_to admin_campaign_index_path
  end

  def campaigns_show
    @campaign = Campaign.where(:campaign_id => params[:id].to_i).first
    # get your manual lookups on, tedium 2 the max SON, don’t care though
    render template: "admin/campaigns/show"
  end

  # code sheets

  def code_sheets_index
    # @objects = CodeSheetPrintRequest.all().limit(10).order("updated_at DESC")
    @objects = CodeSheetPrintRequest.paginate(:page => params[:page]).order("created_at DESC")
    render template: "admin/code_sheets/index"
  end

  def code_sheets_new
    @sheet = CodeSheetPrintRequest.new
    render template: "admin/code_sheets/new"
  end

  def code_sheets_create
    @sheet = CodeSheetPrintRequest.new(sheet_params)
    if params[:patient_residence_id] != ''
      if residence = PatientResidence.where(:patient_residence_id => params[:patient_residence_id].to_i).first
        @sheet.address_line1 = residence.address_line1
        @sheet.address_line2 = residence.address_line2
        @sheet.city = residence.city
        @sheet.state_province = residence.state_province
        @sheet.postal_code = residence.postal_code
        # meh, we should force merica
        # #MERICA SON
        @sheet.country = 'US'
      end
    elsif params[:ship_to_lifesquare_office] != nil and params[:ship_to_lifesquare_office] == "ship-it"
      address = Rails.configuration.office_address
      @sheet.address_line1 = address[:line1]
      @sheet.address_line2 = ''
      @sheet.city = address[:city]
      @sheet.state_province = address[:state_province]
      @sheet.postal_code = address[:postal_code]
      @sheet.country = 'US'
    else
      # bla bla let it pass through, yea son
    end    

    if @sheet.save

      # email admin son, lolzin
      @sheet.notify_admins
      flash[:notice] = "Print Request created! Now download it and print."
      redirect_to admin_code_sheet_index_path
    else
      flash[:notice] = "There were errors creating your print request.<br />Something like… #{@sheet.errors.full_messages}"
      redirect_to admin_code_sheet_new_path
    end
  end

  def code_sheets_show
  end

  # orgs
  def organizations_index
    # @objects = Organization.all().limit(10).order("updated_at DESC")
    @objects = Organization.paginate(:page => params[:page]).order("name ASC")
    render template: "admin/organizations/index"
  end

  def organizations_new
    @organization = Organization.new
    # @plans = get_stripe_plans_for_select
    # get your manual lookups on, tedium 2 the max SON, don’t care though
    render template: "admin/organizations/new"
  end

  def organizations_create
    @organization = Organization.new(organization_params)
    if @organization.save
      flash[:notice] = "Organization created!"
      redirect_to admin_organization_index_path
    else
      flash[:notice] = "There were errors creating your organization.<br />Something like… #{@organization.errors.full_messages}"
      redirect_to admin_organization_new_path
    end
  end

  def organizations_show
    @organization = Organization.where(:organization_id => params[:id].to_i).first
    render template: "admin/organizations/show"
  end

  def organizations_edit
    @organization = Organization.where(:organization_id => params[:id].to_i).first
    render template: "admin/organizations/edit"
  end

  def organizations_update
    # bbla we could use Organization.find params[:id] helper but w/e slacker
    @organization = Organization.where(:organization_id => params[:id].to_i).first
    if @organization.update_attributes(organization_params)
      flash[:notice] = "Organization updated!"
      redirect_to admin_organization_index_path
    else
      flash[:notice] = "There were errors updating your organization.<br />Something like… #{@organization.errors.full_messages}"
      redirect_to admin_organization_edit_path(@organization.id)
    end
  end

  # invoices (for orgs at this point in time)
  def invoices_index
    # @objects = Organization.all().limit(10).order("updated_at DESC")
    @objects = Invoice.paginate(:page => params[:page]).order("created_at ASC")
    render template: "admin/invoices/index"
  end

  def invoices_new
    @invoice = Invoice.new
    # @plans = get_stripe_plans_for_select
    # get your manual lookups on, tedium 2 the max SON, don’t care though
    render template: "admin/invoices/new"
  end

  def invoices_create
    @invoice = Invoice.new(invoice_params)
    if @invoice.save
      flash[:notice] = "Invoice created! Please select notify admins when ready."
      redirect_to admin_invoice_index_path
    else
      flash[:notice] = "There were errors creating your invoice.<br />Something like… #{@invoice.errors.full_messages}"
      redirect_to admin_invoice_new_path
    end
  end

  def invoices_edit
    @invoice = Invoice.where(:invoice_id => params[:id].to_i).first
    render template: "admin/invoices/edit"
  end

  def invoices_update
    # bbla we could use Organization.find params[:id] helper but w/e slacker
    @invoice = Invoice.where(:invoice_id => params[:id].to_i).first
    if @invoice.update_attributes(invoice_params)
      flash[:notice] = "Invoice updated!"
      redirect_to admin_invoice_index_path
    else
      flash[:notice] = "There were errors updating your invoice.<br />Something like… #{@invoice.errors.full_messages}"
      redirect_to admin_invoice_edit_path(@invoice.id)
    end
  end

  # provider credentials
  def provider_credentials_index
    # @objects = Organization.all().limit(10).order("updated_at DESC")
    @objects = ProviderCredential.paginate(:page => params[:page]).order("created_at DESC")
    render template: "admin/provider_credentials/index"
  end

  def provider_credentials_show
    @credentials = ProviderCredential.where(:provider_credential_id => params[:id].to_i).first
    # get your manual lookups on, tedium 2 the max SON, don’t care though
    render template: "admin/provider_credentials/show"
  end

  # CRM town usa™
  # accounts
  def accounts_index
    @objects = Account.paginate(:page => params[:page], :per_page => 10).order("create_date DESC") # it was overriding somehow
    render template: "admin/accounts/index"
  end
  # patients

  # CARE PLANS SON
  def care_plans_index
    @objects = CarePlan.paginate(:page => params[:page], :per_page => 10).order("created_at DESC") # it was overriding somehow
    render template: "admin/care_plans/index"
  end

  def care_plans_new
    @care_plan = CarePlan.new
    render template: "admin/care_plans/new"
  end

  def care_plans_show
    @care_plan = CarePlan.where(:care_plan_id => params[:id].to_i).first
    render template: "admin/care_plans/show"
  end

  def care_plans_update
    @care_plan = CarePlan.from_editor_json(params)
    # inbound json, needs to be split apart up in this bitch, and I'm too lazy to use some standard representation
    # so we're gonna have some manual assembly required, that's ok, son
    # if we were new do the redirect yea son
    if params[:uuid] == nil
      render json: {
        :success => true,
        :redirect_url => admin_care_plan_show_path(@care_plan.id),
        :message => "New Care Plan Created. Redirecting… for laziness"
      }, status: 200
    else
      render json: {
        :success => true,
        :message => "Updated!"
      }, status: 200
    end
  end

  def care_plans_designer
    # this is the primary bizzle
    if params[:id] != nil
      @care_plan = CarePlan.where(:care_plan_id => params[:id].to_i).first
    else
      @care_plan = CarePlan.new
    end
    @organizations = Organization.all.collect { |p| [ p.name, p.id ] }
    render template: "admin/care_plans/designer"
  end

  def question_groups_index
    @objects = CarePlanQuestionGroup.paginate(:page => params[:page], :per_page => 10).order("created_at DESC") # it was overriding somehow
    render template: "admin/care_plans/question_groups/index"
  end

  def questions_index
    @objects = CarePlanQuestion.paginate(:page => params[:page], :per_page => 10).order("created_at DESC") # it was overriding somehow
    render template: "admin/care_plans/questions/index"
  end

  def responses_index
    @objects = CarePlanQuestionResponse.paginate(:page => params[:page], :per_page => 10).order("created_at DESC") # it was overriding somehow
    render template: "admin/care_plans/question_responses/index"
  end

  def recommendations_index
    @objects = CarePlanRecommendation.paginate(:page => params[:page], :per_page => 10).order("created_at DESC") # it was overriding somehow
    render template: "admin/care_plans/recommendations/index"
  end

  def patient_network_new
    @privacy_values = Values.call("privacy")
    @organizations = Organization.all().order(:name)
    render template: "admin/patient_network/new"
  end

  def patient_network_create
    
  end

  # style
  def styleguide
    render template: "admin/styleguide"
  end

  # DEMO design stuffs
  def debug_notification_scan_email
    # setup fakeness to the maxness
    latitude = 37.7043096
    longitude = -122.465604
    results = Geocoder.search("#{latitude},#{longitude}")
    if results.length > 0
      geo = results[0]
    end
    patient = Patient.where(:patient_id => 136).first
    scanner = Patient.where(:patient_id => 167).first
    connection = PatientNetwork.where(:auditor_patient_id => 167, :granter_patient_id => 136).first
    credentials = ProviderCredential.where(:patient_id => 167, :credentialed => true).first
    context = {
      :connection => connection,
      :patient => patient,
      :scanner => scanner,
      :credentials => credentials, # could be nil
      :scantime => Time.now,
      :geo => geo,
      :latitude => latitude,
      :longitude => longitude
    }
    # grab the template 
    render template: "patient_network/mailer/scan_notification", locals: context, layout: 'email' 
  end

  def debug_notification_scansms_email
    # setup fakeness to the maxness
    
    patient = Patient.where(:patient_id => 136).first
    #scanner = Patient.where(:patient_id => 167).first
    #connection = PatientNetwork.where(:auditor_patient_id => 167, :granter_patient_id => 136).first
    #credentials = ProviderCredential.where(:patient_id => 167, :credentialed => true).first
    scanner_phone_number = "+14157703056"
    context = {
      :connection => nil,
      :patient => patient,
      :scanner => nil,
      :scanner_name => PhoneValidator.call_callerid(scanner_phone_number),
      :scanner_phone_number => scanner_phone_number,
      :credentials => nil, # could be nil
      :scantime => Time.now,
      :geo => nil,
      :latitude => nil,
      :longitude => nil
    }
    # grab the template 
    render template: "patient_network/mailer/scan_notification", locals: context, layout: 'email' 
  end

private

  def batch_params
    params.require(:lifesquare_code_batch).permit(:batch_size, :notes)
  end

  def sheet_params
    params.require(:code_sheet_print_request).permit(:lifesquares, :sheets_per_lifesquare, :instructions, :priority, :reprint,
      :address_line1, :address_line2, :city, :state_province, :postal_code)
  end

  def campaign_params
    params.require(:campaign).permit(:name, :campaign_status, :organization_id,
      :start_date, :end_date, :renewal_date, :price_per_lifesquare_per_year, :user_shared_cost_for_campaign,
      :stripe_plan_key, :promo_code, :promo_price, :promo_start_date, :promo_end_date, :description,
      :start_up_fee, :pre_signup_memo, :post_signup_memo, :requires_shipping)
  end

  def organization_params
    params.require(:organization).permit(:name, :ls_name, :slug,
      :contact_first_name, :contact_last_name, :contact_salutation,
      :contact_title, :contact_email, :contact_phone)
  end

  def invoice_params
    params.require(:invoice).permit(:title, :description, :notes, :organization_id,
      :amount, :due_date)
  end

  def care_plan_params
    params.require(:care_plan).permit(:name, :description, :organization_id, :filters)
  end

  def get_stripe_plans_for_select
    begin
      theplans = CreditCardService.get_plans
      plans = []
      theplans.each do |plan|
        plans.push({
          :value => plan.id,
          :name => "#{plan.name} - #{plan.amount} per #{plan.interval}"
          })
      end
      plans
    rescue
      plans = nil
    end
  end
  
  # OG buzzkillers
  def collect_batch_details(batch_id)
    item = {}
    matching = Lifesquare.where(batch_id: batch_id)
    matching_count = matching.count
    item[:id] = batch_id
    item[:count] = matching_count
    unset = Lifesquare.where(:batch_id => batch_id, :valid_state => 0).count
    accepted = Lifesquare.where(:batch_id => batch_id, :valid_state => 1).count
    rejected = Lifesquare.where(:batch_id => batch_id, :valid_state => 2).count
    item[:unset] = unset
    item[:accepted] = accepted
    item[:rejected] = rejected
    item
  end

end