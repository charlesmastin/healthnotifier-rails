class LifesquaresController < ApplicationController
    before_action :authenticate_account!, :except => [:lsqr_home, :lsqr_qrscan] 

    def show_assign
        @patients = Patient.find_by_sql("SELECT DISTINCT patient.*, lifesquare.lifesquare_uid AS lifesquare_code 
                                         FROM patient 
                                         LEFT OUTER JOIN lifesquare ON patient.patient_id = lifesquare.patient_id 
                                         WHERE patient.account_id = #{current_account.account_id} AND patient.status = 'ACTIVE'")
        
        # Display unconfirmed patients, then those without Lifesquares, then the rest
        # @unconfirmed = @patients.find_all{|p| not p.confirmed?}
        without_lifesquares = @patients.find_all{|p| p.confirmed? and p.active? and not p.lifesquare_code_str.present?}
        # with_lifesquares = @patients.find_all{|p| p.lifesquare_code_str.present?}

        # this is an attempt to load in replacement stickers etc, lolzors
        # unconfirmed + with_lifesquares
        @patients = without_lifesquares

        @publishable_key = Rails.configuration.stripe[:publishable_key]
        @total = 0
        if @patients.size >= 1
            # calculate default total cost server side, aka, no promo code
            @patients.each do |patient|
                @total += patient.coverage_cost
            end
            
            @coverage_end = Date.today + 365
            get_addresses
            @cards_on_file = current_account.get_available_cards()

            if @patients.size == 1
                @onboarding_details = calculate_onboarding_progress(@patients[0], 'lifesquare')
            end
        else
            flash[:notice] = 'No confirmed profiles found'
            redirect_to patient_index_path
        end
    end

    def show_replace
        # show a form to facilitate ordering replacements, bulk buy times
        @all_patients = Patient.find_by_sql("SELECT DISTINCT patient.*, lifesquare.lifesquare_uid AS lifesquare_code 
                                         FROM patient 
                                         LEFT OUTER JOIN lifesquare ON patient.patient_id = lifesquare.patient_id 
                                         WHERE patient.account_id = #{current_account.account_id} AND patient.status = 'ACTIVE'")
        with_lifesquares = @all_patients.find_all{|p| p.active? and p.lifesquare_code_str.present?}
        @all_patients = with_lifesquares
        @patients = []

        @publishable_key = Rails.configuration.stripe[:publishable_key]
        @total = 0
        @replacement_cost_per_patient = Rails.configuration.default_replacement_sticker_cost
        if @all_patients.size >= 1
            # sort out the coverage costs and so on
            # consider all dem credits, and have family rollover but for now, no
            # MOVE THIS HERE SHIT TO A MODEL METHOD ON DA PATIENT ASAP SON
            @requires_payment = false
            @all_patients.each_with_index do |patient, index|
                if patient.has_current_coverage
                    if patient.current_coverage.sticker_credits <= 0
                        @requires_payment = true
                        @total += @replacement_cost_per_patient
                    end
                else
                    @requires_payment = true
                    @total += @replacement_cost_per_patient
                end
                @patients.push(patient)
            end

            # if you pay, you renknew your coverage, or something fun like that
            # something more cleverer about moving this to the model,
            # but really it's like rolling enrollment, and you extend from the existing coverage
            # THIS IS WRONG WRONG WRONG WRONG WRONG
            @coverage_start = Date.today
            @coverage_end = Date.today + 365

            get_addresses
            @cards_on_file = current_account.get_available_cards()
            return
        else
            flash[:notice] = 'No profiles with Lifesquares found'
            redirect_to patient_index_path
        end
    end

    def show_renew
        # adhoc coverage renewal
        # qualify only exired peoples, or people in the last 
        # show a form to facilitate ordering replacements, bulk buy times
        @raw_patients = Patient.find_by_sql("SELECT DISTINCT patient.*, lifesquare.lifesquare_uid AS lifesquare_code 
                                         FROM patient 
                                         LEFT OUTER JOIN lifesquare ON patient.patient_id = lifesquare.patient_id 
                                         WHERE patient.account_id = #{current_account.account_id} AND patient.status = 'ACTIVE'")
        with_lifesquares = @raw_patients.find_all{|p| p.lifesquare_code_str.present?}
        @raw_patients = with_lifesquares

        @publishable_key = Rails.configuration.stripe[:publishable_key]
        @total = 0
        
        # todo incorporate into the raw_patients query
        @patients = []
        if @raw_patients.length >= 1
            # sort out the coverage costs and so on
            # consider all dem credits, and have family rollover but for now, no
            @requires_payment = false
            @raw_patients.each do |patient|
                if patient.has_expired_coverage
                    @patients.push(patient)
                    # that is not true
                    cost = patient.coverage_cost
                    if cost > 0
                        @requires_payment = true
                        @total += cost
                    end
                end
            end
        end

        if @patients.length >= 1
            # if you pay, you renknew your coverage, or something fun like that
            # something more cleverer about moving this to the model,
            # but really it's like rolling enrollment, and you extend from the existing coverage
            # THIS IS WRONG WRONG WRONG WRONG WRONG
            @coverage_start = Date.today
            @coverage_end = Date.today + 365

            get_addresses
            @cards_on_file = current_account.get_available_cards()
            return
        else
            flash[:notice] = 'No profiles with Lifesquares found'
            redirect_to patient_index_path
        end
    end

    def lsqr_home
        render :layout => 'lsqr'
        # alt layout son
    end

    def lsqr_qrscan
        # query town USA
        ls = Lifesquare.where(:lifesquare_uid => params[:id]).first
        if ls != nil
            patient = Patient.where(:patient_id => ls.patient_id, :confirmed => true, :status => 'ACTIVE').first
            if patient != nil
                # prefilter bro
                contacts = patient.patient_contacts.select { |c| (c.privacy == "public") && (c.home_phone.presence || c.mobile_phone.presence) }
                render :layout => 'lsqr', :locals => {:ls => ls, :patient => patient, :contacts => contacts }
            else
                render :layout => 'lsqr', :status=>404
                return
            end
        else
            render :layout => 'lsqr', :status=>404
            return
        end
        
        # loggins, and hook the stuffs snuffs bro

        return
        # alt layout son
    end

private

    def get_addresses
        @residences_dupes = PatientResidence.joins(:patient).where(
            'patient.account_id = :account_id',
            {
                :account_id => current_account.account_id,
            })
        # Remove residences with duplicate address lines
        @residences = []
        all_addresses = []
        @residences_dupes.each {|r|
            addr = view_context.format_address(r)
            if not all_addresses.include? addr
                @residences.push(r)
                all_addresses.push(addr)
            end
        }
        # Select the first mailing address
        @selected_residence_index = 0
        @residences.each_with_index {|r, index|
            if r.mailing_address
                @selected_residence_index = index
                break
            end
        }
    end
end