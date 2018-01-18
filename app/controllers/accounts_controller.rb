class AccountsController < ApplicationController
  # TODO: investigate terms update and strip
  # rebuild as needed
  skip_before_action :require_current_tou, :only => :terms_update
  
  if Rails.env.profile?
    before_action :auth_prof
  else
    before_action :authenticate_account!, :except => [:signup_enterprise, :signup_choose]
  end

  layout "application"
  
  def save_signup_refer
    if params.include?(:refer)
      
      current_account.signup_refer = params[:refer]
      
      respond_to do |format|
        if current_account.save
          format.json { render :json => '' }
        else
          format.json { render :json => current_account.errors, :status => :unprocessable_entity }
        end
      end
    end
  end
  
  # GET/POST /account/terms_update
  def terms_update
    if request.get?
       # TODO: maybe in the future, suck down the TOU from the marketing site for inline display here, #nottoday
       # redirect if we have the current terms son
      if current_account.terms_of_use == Rails.configuration.tou_version
        flash[:notice] = 'You have already accepted the latest terms of use'
        redirect_to patients_path
      end
    end

    if request.post?
      if params.include?(:update)
        current_account.terms_of_use = Rails.configuration.tou_version
        respond_to do |format|
          if current_account.save
            account_session[:confirmed_tou_version] = true
            flash[:notice] = 'Thank you for accepting the current HealthNotifier TOU'
            format.html { redirect_to patients_path }
            format.json { render :json => current_account }
          else
            flash[:notice] = 'There was a problem updating your account. Please try again, or contact support@domain.com'
            format.html { redirect_to terms_update_account_path }
            format.json { render :json => current_account.errors, :status => :unprocessable_entity }
          end
        end
      end
    end
  end

  #TODO Create email_friend model for validation & easy spinup? Probably.
  #TODO Clean up and don't leave open for abuse (CSRF!)
  def email_friend
    # TODO: silently ignore bad form, be nice and inform the user
    if params[:message].present? && params[:emails].present?
      name = params[:name].present? ? params[:name] : "Your friend"
      subject = "#{name} thinks you would be interested in HealthNotifier"
      SendBulkEmail.call(params[:emails].split(','), subject, 'accounts/mailer/tell_a_friend', { :name => name, :message => params[:message] })
    end
    respond_to do |format|
      format.html { redirect_to patients_path }
      format.json { render :json => '' }
    end
  end
  
  def tellafriend
  end

  def signup_enterprise
    if current_account != nil
      flash[:notice] = 'You are already signed in.'
      redirect_to patient_index_path
    end
  end

  def signup_choose
    if current_account != nil
      flash[:notice] = 'You are already signed in.'
      redirect_to patient_index_path
    end
  end

private

  def auth_prof
    RubyProf.start
    authenticate_account!
    data = ::RubyProf.stop
    prof_print(data)
  end

  def prof_print(data)
    require 'tmpdir' # late require so we load on demand only
    printers = {::RubyProf::FlatPrinter => ::File.join(Dir.tmpdir, 'profile.txt'),
                ::RubyProf::GraphHtmlPrinter => ::File.join(Dir.tmpdir, 'profile.html')}
  
    printers.each do |printer_klass, file_name|
      printer = printer_klass.new(data)
      ::File.open(file_name, 'wb') do |file|
        printer.print(file, :min_percent => 0.00000001 )
      end
    end
  end
end
