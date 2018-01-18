namespace :healthnotifier do
  desc "check for expired provider credentials and deal with them"
  task :process_expired_providers => :environment do
    ProcessExpiredProviders.call
  end

  # Scheduled task
  # Handles coverage reminders for all Lifesquares that are not associated with a campaign
  desc "scheduled job that checks coverage status for Lifesquare patients not associated with a campaign"
  def check_non_campaign_patient_coverages
    lead_time_for_reminder_in_days = 30
    patient_info_by_lifesquare_uid = {}
    no_campaign_lifesquares = Lifesquare.find(:all, :conditions => {:campaign_id => nil})
    no_campaign_lifesquares.each do |one_lifesquare|
      patient_info_by_lifesquare_uid = one_lifesquare.check_for_pending_coverage_expiration(patient_info_by_lifesquare_uid,
                                                                                            lead_time_for_reminder_in_days)
    end
    # Now send email reminders
    patient_info_by_lifesquare_uid.each do |lifesqure_uid, info_hash|
      account = info_hash[:account]
      patient = info_hash[:patient]
      coverage_end = info_hash[:coverage_end]
      account.send_non_campaign_coverage_renewal_reminder(patient, coverage_end, subject)
    end
  end

  # Scheduled task
  # Handles Lifesquares that were under a campaign, but then, for whatever reason, the campaign goes
  # inactive and the patient's subscription is now patient owned OR there is a shared cost for the
  # patient
  desc "scheduled job that checks coverage status for Lifesquare patients associated with a campaign"
  def check_campaign_patient_coverages
    lead_time_for_reminder_in_days = 30
    all_campaigns = Campaign.find(:all)
    all_campaigns.each do |one_campaign|
      if(one_campaign.status.eql?(Campaign::Status::ACTIVE) and
        one_campaign.user_shared_cost_for_campaign.eql?(0))
        next
      end
      patient_info_by_lifesquare_uid= {}
      lifesquares_for_campaign = one_campaign.lifesquares
      lifesquares_for_campaign.each do |one_lifesquare|
        patient_info_by_lifesquare_uid = one_lifesquare.check_for_pending_coverage_expiration(patient_info_by_lifesquare_uid,
                                                                                              lead_time_for_reminder_in_days)
      end
      # Now send email reminders
      patient_info_by_lifesquare_uid.each do |lifesqure_uid, info_hash|
        account = info_hash[:account]
        patient = info_hash[:patient]
        coverage_end = info_hash[:coverage_end]
        account.send_campaign_coverage_renewal_reminder(patient, coverage_end, one_campaign)
      end
    end
  end

  #TODO FOR RAM: CREATE LAST_SUBSCRIPTION_REMINDER_SENT COLUMN FOR PATIENT SO THAT WE CAN
  # AVOID SENDING ANY MORE THAN ONCE A WEEK

  # Scheduled Task
  # Checks campaigns that are about to expire and sends an email to support and the campaign contact
  # at the campaign.organization level (organization.contact_email).  This will then trigger an internal
  # business process to address campaign status and sponsorship and any other sundries.
  def screen_for_campaign_expiration
    
  end

  # Non-cronned rake task that is invoked when a campaign shared cost changes.
  # This task will null the stripe_subscription_key on the coverage object.
  # Additionally it will call Coverage.cancel_subscription.  It should then
  # email the user (where account is the one associated with an email address)
  # and tell them that the sponsoring entity has changed the dollar value
  # of sponsorship.
  def change_campaign_sponsorship_level

  end




end
