module Api
  class PatientNetworkController < Api::ApplicationController
    before_action :authenticate_account
    before_action :establish_patient, except: [:admin_search, :admin_request_access, :admin_create_connections, :admin_get_granters_count]
    before_action :require_lifesquare_employee, only: [:admin_search, :admin_request_access, :admin_create_connections, :admin_get_granters_count]
    # permissions are per method but we could decorate with an action for external clarity

    # names are not crud centric here, because they wrap various semantic nuances
    
    def index
      # yea son son son
      json = {
        :granters => @patient.network_granters.all,
        :granters_pending => @patient.network_granters_pending.all,
        :auditors => @patient.network_auditors.all,
        :auditors_pending => @patient.network_auditors_pending.all,
      }

      render json: json

    end

    def search
      # yup this here sauce mcgees
      if !(keywords = params[:keywords])
        @patient.errors[:base] << 'search keywords not provided'
      else
        arrayfound = search_for_patients(keywords)
        if !arrayfound.empty?
          groupname = params[:group]
          if (groupname == 'auditors')
            patnetsexclude = @patient.network_auditors.all
            patnetidattr = :auditor_patient_id
          elsif (groupname == 'granters')
            patnetsexclude = @patient.network_granters.all
            patnetidattr = :granter_patient_id
          else
            patnetsexclude = []
          end
          patnetsexclude.each do |patnet|
            arrayfound.delete_if do |element|
              pat = element[0] # we are ignoring the address in element[1]
              pat.patient_id == patnet[patnetidattr]
            end
          end
          @patient.account.active_patients.each do |p|
            arrayfound.delete_if do |element|
              pat = element[0] # we are ignoring the address in element[1]
              pat.patient_id == p.patient_id
            end
          end
        end
        jsonarray = []
        idpatcur = @patient.patient_id
        arrayfound.each do |element|
          pat = element[0] # we are ignoring the address in element[1]

          # FIND ANY PENDING STATUS YOU LITTLE LITTLE
          # BLOW THIS BUZINESS AWAY IT"S SUCH A DOUBLE QUERY SLOPFEST

          auditor_patient = @patient.network_auditors.
            find_by_granter_patient_id_and_auditor_patient_id(
              idpatcur, pat.patient_id)
          isauditor = (nil != auditor_patient)
          auditor_privacy = isauditor ? auditor_patient.privacy : ''

          granter_patient = @patient.network_granters.
            find_by_granter_patient_id_and_auditor_patient_id(
              pat.patient_id, idpatcur)
          isgranter = (nil != granter_patient)
          granter_privacy   = isgranter ? granter_patient.privacy : ''
          granter_join_date = isgranter ? granter_patient.joined_at : ''

          pending_granter_patient = @patient.network_granters_pending.
            find_by_granter_patient_id_and_auditor_patient_id(
              pat.patient_id, idpatcur)
          ispendinggranter = (nil != pending_granter_patient)


          jsonarray.push({
            :patient_id => pat.patient_id.to_s,
            :PatientUuid => pat.uuid,
            :PatientPhotoUuid => pat.photo_uid, # WTF BRA
            #:LifesquareId => pat.lifesquare_code_str,
            :Name => pat.name_extended,
            :FirstName => pat.first_name,
            :LastName => pat.last_name,
            #:Age => pat.age_str,
            :Photo => pat.photo_uid,
            :IsProvider => pat.account.provider?,
            :IsAuditor => isauditor,
            :AuditorPrivacy => auditor_privacy,
            :IsGranter => isgranter,
            :GranderPrivacy => granter_privacy,
            :GranterJoinDate => granter_join_date,
            :IsPendingGranter => ispendinggranter,
          })
        end
        render json: {
          :Patients => jsonarray
        }
        return
      end
      render json: @patient.errors, status: :unprocessable_entity
    end

    def add
      begin
        auditor = Patient.where(:uuid => params[:AuditorId], :status => 'ACTIVE').first
        granter = Patient.where(:uuid => params[:GranterId], :status => 'ACTIVE').first
        if granter != @patient
          render json: {
            :success => false,
            :message => "Permission Denied"
          }, status: 403
        end
        # TODO: needs a new method to set Deleted, but not delete, for record keeping son
        # TODO: Sort out this db modelling, at some point soonish
        patnet = @patient.invite_into_network(auditor, {:privacy => params[:Privacy]})
       
        # STOP WITH EXCESSIVE EMAIL VALIDATION
        notified = SNSNotification.network_access_granted(auditor, granter)
        if notified == 0
          AccountMailer.send_email(
            auditor.account.email,
            "Lifesquare patient network added",
            'patient_network/mailer/auditor_added',
            {:auditor => auditor, :granter => granter}
          ).deliver_later
        end
        render json: {
          :success => true,
          :message => "Request added!"
        }, status: 200
        return
      rescue
        render json: {
          :success => false,
          :message => "Invalid Request"
        }, status: 400 
        return
      end
    end

    def request_access
      begin
        auditor = Patient.where(:uuid => params[:AuditorId], :status => 'ACTIVE').first
        granter = Patient.where(:uuid => params[:GranterId], :status => 'ACTIVE').first
        # do we care about auth'd patient vs auditor, not really
        if auditor != @patient
          render json: {
            :success => false,
            :message => "Permission Denied"
          }, status: 403
        end
        patnet = @patient.ask_to_join_network(granter)
        # STOP WITH EXCESSIVE EMAIL VALIDATION

        # if push, if not, fallback to dat email
        # however may not be entirely reachable, lol
        notified = SNSNotification.network_request_access(auditor, granter)
        if notified == 0
          AccountMailer.send_email(
            granter.account.email,
            "Lifesquare patient network request",
            'patient_network/mailer/granter_request',
            {:auditor => auditor, :granter => granter}
          ).deliver_later
        end

        render json: {
          :success => true,
          :message => "Invite sent!"
        }, status: 200
        return
      rescue
        render json: {
          :success => false,
          :message => "Invalid Request"
        }, status: 400 
        return
      end
    end

    def accept
      begin
        auditor = Patient.where(:uuid => params[:AuditorId], :status => 'ACTIVE').first
        granter = Patient.where(:uuid => params[:GranterId], :status => 'ACTIVE').first
        if granter != @patient
          render json: {
            :success => false,
            :message => "Permission Denied"
          }, status: 403
        end
        patnet = @patient.accept_into_network(auditor, params[:Privacy])
        # STOP WITH EXCESSIVE EMAIL VALIDATION
        notified = SNSNotification.network_access_granted(auditor, granter)
        if notified == 0
          AccountMailer.send_email(
            auditor.account.email,
            "Lifesquare patient network request accepted",
            'patient_network/mailer/auditor_request_accepted',
            {:auditor => auditor, :granter => granter}
          ).deliver_later
        end
        render json: {
          :success => true,
          :message => "Request accepted!"
        }, status: 200
        return
      rescue
        render json: {
          :success => false,
          :message => "Invalid Request"
        }, status: 400 
        return
      end
    end

    def decline
      begin
        auditor = Patient.where(:uuid => params[:AuditorId], :status => 'ACTIVE').first
        granter = Patient.where(:uuid => params[:GranterId], :status => 'ACTIVE').first
        if granter != @patient
          render json: {
            :success => false,
            :message => "Permission Denied"
          }, status: 403
        end
        # TODO: needs a new method to set Deleted, but not delete, for record keeping son
        # TODO: Sort out this db modelling, at some point soonish
        # patnet = @patient.decline_network(auditor)
        patnet = PatientNetwork.where(:auditor_patient_id => auditor.patient_id, :granter_patient_id => granter.patient_id).first
        patnet.destroy
        # STOP WITH EXCESSIVE EMAIL VALIDATION

        notified = SNSNotification.network_request_declined(auditor, granter)
        if notified == 0
          AccountMailer.send_email(
            auditor.account.email,
            "Lifesquare patient network request declined",
            'patient_network/mailer/auditor_request_declined',
            {:auditor => auditor, :granter => granter}
          ).deliver_later
        end

        render json: {
          :success => true,
          :message => "Request declined!"
        }, status: 200
        return
      rescue
        render json: {
          :success => false,
          :message => "Invalid Request"
        }, status: 400 
        return
      end
    end

    def update
      begin
        auditor = Patient.where(:uuid => params[:AuditorId], :status => 'ACTIVE').first
        granter = Patient.where(:uuid => params[:GranterId], :status => 'ACTIVE').first
        if granter != @patient
          render json: {
            :success => false,
            :message => "Permission Denied"
          }, status: 403
        end
        # TODO: needs a new method to set Deleted, but not delete, for record keeping son
        # TODO: Sort out this db modelling, at some point soonish
        # patnet = @patient.decline_network(auditor)
        patnet = PatientNetwork.where(:auditor_patient_id => auditor.patient_id, :granter_patient_id => granter.patient_id).first
        patnet.privacy = params[:Privacy]
        patnet.save
        
        render json: {
          :success => true,
          :message => "Permissions updated!"
        }, status: 200
        return
      rescue
        render json: {
          :success => false,
          :message => "Invalid Request"
        }, status: 400 
        return
      end
    end

    def revoke
      begin
        auditor = Patient.where(:uuid => params[:AuditorId], :status => 'ACTIVE').first
        granter = Patient.where(:uuid => params[:GranterId], :status => 'ACTIVE').first
        if granter != @patient
          render json: {
            :success => false,
            :message => "Permission Denied"
          }, status: 403
        end
        # TODO: needs a new method to set Deleted, but not delete, for record keeping son
        # TODO: Sort out this db modelling, at some point soonish
        # patnet = @patient.decline_network(auditor)
        patnet = PatientNetwork.where(:auditor_patient_id => auditor.patient_id, :granter_patient_id => granter.patient_id).first
        patnet.destroy
        # STOP WITH EXCESSIVE EMAIL VALIDATION
        notified = SNSNotification.network_access_revoked(auditor, granter)
        if notified == 0
          AccountMailer.send_email(
            auditor.account.email,
            "Lifesquare patient network access revoked",
            'patient_network/mailer/auditor_removed',
            {:auditor => auditor, :granter => granter}
          ).deliver_later
        end
        render json: {
          :success => true,
          :message => "Request revoked!"
        }, status: 200
        return
      rescue => e
        render json: {
          :success => false,
          :message => "Invalid Request"
        }, status: 400 
        return
      end
    end

    def leave
      begin
        auditor = Patient.where(:uuid => params[:AuditorId], :status => 'ACTIVE').first
        granter = Patient.where(:uuid => params[:GranterId], :status => 'ACTIVE').first
        if auditor != @patient
          render json: {
            :success => false,
            :message => "Permission Denied"
          }, status: 403
        end
        patnet = PatientNetwork.where(:auditor_patient_id => auditor.patient_id, :granter_patient_id => granter.patient_id).first
        patnet.destroy
        # STOP WITH EXCESSIVE EMAIL VALIDATION
        AccountMailer.send_email(
          granter.account.email,
          "Lifesquare patient network left",
          'patient_network/mailer/granter_connection_left',
          {:auditor => auditor, :granter => granter}
        ).deliver_later
        render json: {
          :success => true,
          :message => "Network left!"
        }, status: 200
        return
      rescue
        render json: {
          :success => false,
          :message => "Invalid Request"
        }, status: 400 
        return
      end
    end

    # admin actions
    def admin_request_access
      auditor_patient = Patient.where(:uuid => params[:auditor_patient_uuid]).first
      lifesquares = admin_query_granters
      privacy = params[:connection_privacy]

      connections = []

      lifesquares.each do |lsq|
        # convert to patient
        granter_patient = Patient.where(:patient_id => lsq.patient_id).first
        # we should check how fault tolerant the networking code is, so it can just step past existing connections
        # TODO: support the request reason though
        patnet = auditor_patient.ask_to_join_network(granter_patient)
        # check if we're a new one bro
        if patnet != nil
          AccountMailer.send_email(
            granter_patient.account.email,
            "Lifesquare patient network request",
            'patient_network/mailer/granter_request',
            {:auditor => auditor_patient, :granter => granter_patient}
          ).deliver_later
          connections.append(patnet)
        end

      end

      # summary info , # log it

      # jSON response
      render json: {
        :connections_count => connections.length,
        :granters_count => lifesquares.length,
        :success => true,
        :message => "Connections Requested"
      }, status: 200

    end

    def admin_create_connections
      auditor_patient = Patient.where(:uuid => params[:auditor_patient_uuid]).first
      lifesquares = admin_query_granters
      privacy = params[:connection_privacy]

      connections = []

      lifesquares.each do |lsq|
        # convert to patient
        granter_patient = Patient.where(:patient_id => lsq.patient_id).first
        raw_connection = PatientNetwork.where(:auditor_patient_id => auditor_patient.patient_id, :granter_patient_id => granter_patient.patient_id).first
        connection = nil
        if raw_connection == nil
          new_connection = PatientNetwork.create(
            :auditor_patient_id => auditor_patient.patient_id,
            :granter_patient_id => granter_patient.patient_id,
            :privacy => privacy,
            :asked_at => Time.now,
            :joined_at => Time.now,
            :request_reason => 'Campaign TOS'
          )
          connection = new_connection
          connections.push(connection)
        elsif raw_connection.joined_at == nil
          # this is hmm, not setting privacy, let's think about that
          # we no longer request privacy, so we must establish it
          raw_connection.privacy = privacy
          raw_connection.joined_at = Time.now
          raw_connection.request_reason = 'Campaign TOS'
          raw_connection.save
          connection = raw_connection
          connections.push(connection)
        end

        campaign = lsq.campaign
        organization = lsq.campaign.organization

        # invoke mailers
        # patient_network/mailer/granter_auto_connection
        if connection != nil
          AccountMailer.send_email(
            connection.granter_patient.account.email,
            "Lifesquare patient network connection auto-created",
            'patient_network/mailer/granter_auto_connection',
            {:connection => connection, :organization => organization, :campaign => campaign }
          ).deliver_later
        end
      end

      # summary mailer to auditor
      if connections.length > 0
        AccountMailer.send_email(
          auditor_patient.account.email,
          "Lifesquare patient network connection auto-created",
          'patient_network/mailer/auditor_auto_connections',
          {:connections => connections}
        ).deliver_later
      end

      # JSON response with summary info for the audit, so we can redirect to that URL
      render json: {
        :connections_count => connections.length,
        :granters_count => lifesquares.length,
        :success => true,
        :message => "Connections Created"
      }, status: 200

    end

    def admin_manage_connections
      # depending on action do a couple different things though
    end

    # does nothing more than admin_query_granters.count
    def admin_get_granters_count
      lifesquares = admin_query_granters
      render json: {
        :granters_count => lifesquares.length,
        :success => true,
        :message => "That's cool bro"
      }, status: 200
    end

    def admin_search
      # TODO: as we open this up for more purposes
      # we will need to return deleted patients and mark them as such in the UI... mmmkay
      # this is currently only used to specifcy Auditors
      words = params[:keywords].split(' ') # this bombs on certain email lookups, we need better logic
      patients = []
      # we're DAMN specific here, so it's way too much effort to go into the general patient search and branch the code
      account = Account.where("lower(email) = ? AND account_status = 'ACTIVE'", params[:keywords].downcase).first
      if account != nil
        for patient in account.active_patients
          patients.append(patient)
        end
      end
      # try on patient first and last name
      if words.length == 2
        results = Patient.where("lower(first_name) = ? AND lower(last_name) = ? AND status = 'ACTIVE'", words[0].downcase, words[1].downcase)
        for patient in results
          patients.append(patient)
        end
      end
      # iterate results, and do your shizzle nizzle
      json = []
      for patient in patients
        node = {
          :profile => {
            :first_name => patient.first_name,
            :last_name => patient.last_name,
            :fullname => patient.fullname,
            :photo_uuid => patient.photo_uid,
            :lifesquare_id => patient.lifesquare_uid_str,
            :uuid => patient.uuid,
            :confirmed => patient.confirmed,
            :current_coverage => patient.current_coverage,
            :network => {
              :granters_count => patient.network_granters.all.count,
              :granters_pending_count => patient.network_granters_pending.all.count,
              :auditors_count => patient.network_auditors.all.count,
              :auditors_pending_count => patient.network_auditors_pending.all.count,
            }
          },
          :account => {
            :email => patient.account.email,
            :phone => patient.account.mobile_phone,
            :uuid => patient.account.uid,
            :provider => patient.account.provider?,
            :organization => "TBD",
            :sign_in_count => patient.account.sign_in_count,
            :current_sign_in_at => patient.account.current_sign_in_at,
            :last_sign_in_at => patient.account.last_sign_in_at,
            :confirmed => patient.account.confirmed_at,
            :signup_platform => patient.account.signup_platform
          }
        }
        json.append(node)
      end
      render json: {
        :results => json
      }
    end

    # this is really a util somewhere, not a method here
    def admin_query_granters
      # WE CAN'T CONNECT TO PEOPLE WITHOUT LIFESQUARES
      # However the auditor can be a provider who is sans Lifesquare
      # let's be real, we need patients, not lifesquares, it's just one way of getting there
      # let's do this with only patients OK
      lifesquares = []
      if params[:granter_organization_uuid] != nil
        organization = Organization.where(:uuid => params[:granter_organization_uuid]).first
        if organization != nil
          campaigns = Campaign.where(:organization_id => organization.organization_id)
          campaigns.each do |campaign|
            # I think this works
            lifesquares += Lifesquare.where(:campaign_id => campaign.campaign_id).where.not(patient_id: nil)
          end
        end
      end
      if params[:granter_campaign_uuid] != nil
        campaign = Campaign.where(:uuid => params[:granter_campaign_uuid]).first
        if campaign != nil
          lifesquares = Lifesquare.where(:campaign_id => campaign.campaign_id).where.not(patient_id: nil)
        end
      end
      if params[:granter_patient_uuid] != nil
        patient = Patient.where(:uuid => params[:granter_patient_uuid]).first
        if patient != nil
          lifesquare = Lifesquare.where(:patient_id => patient.patient_id).first
          if lifesquare != nil
            lifesquares.append(lifesquare)
          end
        end
      end
      lifesquares
    end

  end
end
