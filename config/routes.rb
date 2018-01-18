HealthNotifierModule::Application.routes.draw do
  #############################################################################
  #
  #     Index and static pages (that should go do hugo)
  #
  #############################################################################
  root :to => 'application#home'
  match 'home' => 'application#home', :as => :home, via: [:get] # clicking the "logo"
  match 'goodbye' => 'application#goodbye', :as => :goodbye, via: [:get] # this is after deleting your account
  match 'exit-survey/success' => 'application#exit_survey_success', :via => [:get], :as => :exit_survey_success

  #############################################################################
  #
  #     API - v1+ and some older in-use routes for mobile (RIP soon!)
  #
  #############################################################################
  
  match 'api/v1/auth/reminder' => 'api/accounts#password_reminder', via: [:post]
  # legacy endpoints
  match 'api/v1/auth/login' => 'api/sessions#create', :as => :api_auth_create, via: [:post]
  match 'api/v1/auth/logout' => 'api/sessions#destroy', :as => :api_auth_destroy, via: [:delete]
  # new JWT Oauth2 token stuffs
  match 'api/v1/oauth/access_token' => 'api/oauth#grant', :as => :api_oauth_grant, via: [:post]
  match 'api/v1/oauth/revoke_token' => 'api/oauth#revoke', :as => :api_oauth_revoke, via: [:post]

  match 'api/v1/accounts/password-reminder' => 'api/accounts#password_reminder', :as => :api_auth_reminder, via: [:post]
  match 'api/v1/accounts/begin-recovery' => 'api/accounts#begin_recovery', :as => :api_begin_recovery, via: [:post]
  match 'api/v1/accounts/recover' => 'api/accounts#recover', :as => :api_recover, via: [:post]
  match 'api/v1/accounts/complete-recovery' => 'api/accounts#complete_recovery', :as => :api_complete_recovery, via: [:post]
  match 'api/v1/account' => 'api/accounts#create', via: [:post]
  match 'api/v1/accounts' => 'api/accounts#create', :as => :api_account_create, via: [:post]
  match 'api/v1/accounts/basic' => 'api/accounts#create_basic', :as => :api_account_create_basic, via: [:post]
  match 'api/v1/accounts/enterprise' => 'api/accounts#create_enterprise', :as => :api_account_create_enterprise, via: [:post] # same end point for enterprise as well bro
  match 'api/v1/accounts/notifications' => 'api/accounts#notifications', :as => :api_notifications, via: [:get]
  match 'api/v1/accounts/location' => 'api/accounts#update_location', :as => :api_account_update_location, via: [:post, :put]
  match 'api/v1/accounts/:uid' => 'api/accounts#get', :as => :api_account_get, via: [:get]
  match 'api/v1/accounts/:uid' => 'api/accounts#update', :as => :api_account_update, via: [:put, :post]
  match 'api/v1/accounts/:uid' => 'api/accounts#delete', :as => :api_account_delete, via: [:delete]
  match 'api/v1/accounts/:uid/verify-credentials' => 'api/accounts#verify_credentials', :as => :api_account_verify_credentials, via: [:post]

  match 'api/v1/devices' => 'api/accounts#create_device', :as => :api_account_create_device, via: [:post] # misleading name, but basically save/update token for a device
  # match 'api/v1/devices' => 'api/accounts#update_device', :as => :api_account_update_device, via: [:put] # client is not self-aware of our domain objects nor is it a concern
  # match 'api/v1/devices/:uuid' => 'api/accounts#delete_device', :as => :api_account_delete_device, via: [:delete] # probably for administrative in our admin, and for future user features

  # enterprise / business accounts
  match 'api/v1/orgs/:uuid/order-lifesquares' => 'api/organizations#order_lifesquares', as: :api_org_order_lifesquares, via: [:post]
  match 'api/v1/orgs/:uuid/renew-lifesquares' => 'api/organizations#renew_lifesquares', as: :api_org_renew_lifesquares, via: [:post]
  match 'api/v1/orgs/:uuid/invoices/:invoice_uuid' => 'api/organizations#charge_invoice', as: :api_org_charge_invoice, via: [:post]
  match 'api/v1/orgs/:uuid/invoices/:invoice_uuid/notify' => 'api/organizations#notify_invoice', as: :api_org_notify_invoice, via: [:post]
  match 'api/v1/orgs/:uuid/search' => 'api/organizations#member_search', as: :api_org_member_search, via: [:get]

  # oddly enough enough a lifesquare is a uuid, but for our own domain, so we could say :lifesquare :)
  match 'api/v1/lifesquare/:id/webview' => 'api/lifesquares#webview', via: [:get]
  match 'api/v1/lifesquare/my-lifesquare' => 'api/lifesquares#scan', :as => :api_lifesquare_scan_my_lifesquare, :mine => true, via: [:get]
  match 'api/v1/lifesquares/nearby' => 'api/lifesquares#nearby', :as => :api_lifesquare_nearby, via: [:get]
  match 'api/v1/lifesquares/search' => 'api/lifesquares#search', :as => :api_lifesquare_search, via: [:get]
  match 'api/v1/lifesquares/assign' => 'api/lifesquares#assign', :as => :api_lifesquares_assign, via: [:post]
  match 'api/v1/lifesquares/renew' => 'api/lifesquares#renew', :as => :api_lifesquares_renew, via: [:post]
  match 'api/v1/lifesquares/replace' => 'api/lifesquares#replace', :as => :api_lifesquares_replacements, via: [:post]
  match 'api/v1/lifesquares/validate' => 'api/lifesquares#validate', :as => :api_lifesquares_validate, via: [:post] # combo validator and checkout helper
  match 'api/v1/lifesquares/create-batch' => 'api/lifesquares#create_batch', :as => :api_create_batch, via: [:post]
  match 'api/v1/lifesquare/:id(.:format)' => 'api/lifesquares#scan', via: [:get]
  match 'api/v1/lifesquares/:id(.:format)' => 'api/lifesquares#scan', :as => :api_lifesquare_scan, via: [:get]
  match 'api/v1/lifesquares/:id/image' => 'api/lifesquares#image', :as => :api_lifesquare_image, via: [:get]
  match 'api/v1/lifesquares/:id/webview' => 'api/lifesquares#webview', :as => :api_lifesquare_webview, via: [:get]
  
  match 'api/v1/document/view/:uid' => 'api/documents#collection_view', :as => :api_document_view, via: [:get]
  match 'api/v1/document' => 'api/documents#create', via: [:post]
  match 'api/v1/document/:uid' => 'api/documents#get', via: [:get]
  match 'api/v1/document/:uid' => 'api/documents#delete', via: [:delete]
  match 'api/v1/documents' => 'api/documents#create', :as => :api_document_upload, via: [:post]
  match 'api/v1/documents/:uid' => 'api/documents#delete', :as => :api_document_delete, via: [:delete]
  match 'api/v1/documents/:uid' => 'api/documents#get', :as => :api_document_get, via: [:get]
  match 'api/v1/documents/:uid' => 'api/documents#update', :as => :api_document_update, via: [:patch]
  match 'api/v1/file/retrieve/:uid' => 'api/documents#retrieve_file', :as => :api_file_retrieve, via: [:get]
  match 'api/v1/files/:uid' => 'api/documents#retrieve_file', :as => :api_file_retrieve_new, via: [:get]

  match 'api/v1/provider-credentials' => 'api/providers#register', :as => :api_provider_credentials, via: [:post]
  match 'api/v1/patients' => 'api/patients#index', via: [:get]
  match 'api/v1/profiles' => 'api/patients#index', :as => :api_patients_list, via: [:get]
  match 'api/v1/profiles' => 'api/patients#create', :as => :api_patients_create, via: [:post] # NOT IN USE
  match 'api/v1/profiles/basic' => 'api/patients#create_basic', :as => :api_patients_create_basic, via: [:post] # Temp for new app onboarding, fold back to /profiles
  match 'api/v1/profiles/:uuid' => 'api/patients#show', :as => :api_patient_show, via: [:get]
  match 'api/v1/profiles/:uuid' => 'api/patients#update', :as => :api_patient_update, via: [:put, :post]
  match 'api/v1/profiles/:uuid' => 'api/patients#delete', :as => :api_patient_delete, via: [:delete]
  match 'api/v1/profiles/:uuid/confirm' => 'api/patients#confirm', :as => :api_patient_confirm, via: [:put, :post]
  match 'api/v1/profiles/:uuid/export' => 'api/patients#export', :as => :api_patient_export, via: [:get]
  match 'api/v1/profiles/:uuid/import' => 'api/patients#import', :as => :api_patient_import, via: [:post, :put]
  match 'api/v1/profiles/:uuid/profile-photo' => 'api/patients#profile_photo', :as => :api_patient_photo, via: [:get, :post, :put, :delete]
  match 'api/v1/profiles/:uuid/emr-lookup' => 'api/patients#emr_patient_search', :as => :api_patient_emr_lookup, via: [:get, :post] # TODO: params for get, vs json body for post - keep it off logs?
  match 'api/v1/profiles/:uuid/coverage-subscription' => 'api/patients#coverage_cancel_recurring', :as => :api_coverage_cancel_recurring, via: [:delete]
  match 'api/v1/profiles/:uuid/emergency-contacts/confirm' => 'api/patients#confirm_emergency_contacts', :as => :api_patient_confirm_emergency_contacts, via: [:post]
  match 'api/v1/profiles/:uuid/emergency-contacts/message' => 'api/patients#message_emergency_contacts', :as => :api_patient_message_emergency_contacts, via: [:post]
  match 'api/v1/profiles/:uuid/popular-terms/:category' => 'api/patients#popular_terms', via: [:get]
  # uuid here is the authenticated user profile in the portal, so it maybe either granter or auditor, that's ok
  match 'api/v1/profiles/:uuid/network' => 'api/patient_network#index', as: :api_network_index, via: [:get]
  match 'api/v1/profiles/:uuid/network/search' => 'api/patient_network#search', as: :api_network_search, via: [:get]
  match 'api/v1/profiles/:uuid/network/add' => 'api/patient_network#add', as: :api_network_add, via: [:post]
  match 'api/v1/profiles/:uuid/network/request-access' => 'api/patient_network#request_access',   as: :api_network_request,   via: [:post]
  match 'api/v1/profiles/:uuid/network/accept' => 'api/patient_network#accept', as: :api_network_accept, via: [:post, :put]
  match 'api/v1/profiles/:uuid/network/decline' => 'api/patient_network#decline', as: :api_network_decline, via: [:post, :put]
  match 'api/v1/profiles/:uuid/network/update' => 'api/patient_network#update', as: :api_network_update, via: [:put]
  match 'api/v1/profiles/:uuid/network/revoke' => 'api/patient_network#revoke', as: :api_network_revoke, via: [:delete]
  match 'api/v1/profiles/:uuid/network/leave' => 'api/patient_network#leave', as: :api_network_leave, via: [:delete]
  # care plans
  match 'api/v1/profiles/:uuid/advise-me' => 'api/care_plans#index', as: :api_care_plans_list, via: [:get]
  match 'api/v1/profiles/:uuid/advise-me/response' => 'api/care_plans#process_response', as: :api_care_plans_process_response, via: [:post]
  match 'api/v1/profiles/:uuid/advise-me/advice/:recommendation_uuid' => 'api/care_plans#recommendation_show', :as => 'api_care_plans_recommendation', via: [:get]
  match 'api/v1/profiles/:uuid/advise-me/question-group/:question_group_uuid' => 'api/care_plans#question_group', :as => 'api_care_plans_question_group', via: [:get]

  # the mighty collection 
  resources :patients, :except => [:edit], :path => 'api/v1/profiles', :controller => 'api/patients' do
    collection_names_whitelist = /documents|directives|conditions|procedures|immunizations|patient_(allergies|languages|residences|contacts|therapies|health_events|care_providers|medical_facilities|health_attributes|insurances|pharmacies|immunizations)/
    collection do
      scope(:constraints => { :collection_name  => collection_names_whitelist }, :defaults => { :format => 'json' }) do
        get ':uuid/:collection_name', :action => :collection_index
        match ':uuid/:collection_name', :action => :collection_write, :via => [:post, :put]
      end
    end
  end
  
  match 'api/v1/term-lookup/search' => 'api/term_lookup#search', via: [:get]
  match 'api/v1/term-lookup/medication' => 'api/term_lookup#medication_detail', via: [:get]
  match 'api/v1/parser/drivers-license' => 'api/application#parse_license', via: [:post]
  match 'api/v1/validate-address' => 'api/application#validate_address', via: [:get] # easier to send a json document than a bunch of get params, IMO
  match 'api/v1/validate-phone/:number' => 'api/application#validate_phone', via: [:get]
  match 'api/v1/tellafriend' => 'accounts#tellafriend', :via => [:post], :as => :api_tellafriend
  match 'api/v1/exit-survey' => 'api/accounts#exit_survey', :via => [:post], :as => :api_exit_survey

  # values API, generic (attribute could be nil if not relevant, could use the optional param syntax)
  match 'api/v1/values' => 'api/application#all_values', via: [:get]
  match 'api/v1/values/:model' => 'api/application#values', via: [:get]
  match 'api/v1/values/:model/:attribute' => 'api/application#values', via: [:get]

  match 'api/v1/static/terms' => 'api/application#static_terms', via: [:get]
  match 'api/v1/static/privacy' => 'api/application#static_privacy', via: [:get]


  # internal API utilities, naming can change on a dime, as it's interal and using named routes
  match 'api/v1/code-sheet-print-request/:id' => 'api/code_sheet_print_request#show', via: [:get], :as => :api_print_data
  match 'api/v1/code-sheet-print-request/:id/download' => 'api/code_sheet_print_request#download', via: [:get], :as => :api_download_print_request
  match 'api/v1/code-sheet-print-request/:id/status/:status' => 'api/code_sheet_print_request#update_status', via: [:post], :as => :api_update_print_request_status

  match 'api/v1/provider-credentials/:id/approve' => 'api/providers#approve_request', :as => :api_provider_credentials_approve, via: [:post]
  match 'api/v1/provider-credentials/:id/deny' => 'api/providers#deny_request', :as => :api_provider_credentials_deny, via: [:post]

  # admin APIs
  match 'api/v1/admin/network/request-access' => 'api/patient_network#admin_request_access',   as: :api_network_admin_request_access,   via: [:post]
  match 'api/v1/admin/network/create-connections' => 'api/patient_network#admin_create_connections',   as: :api_network_admin_create_connections,   via: [:post]
  match 'api/v1/admin/network/get-granters-count' => 'api/patient_network#admin_get_granters_count',   as: :api_network_admin_get_granters_count,   via: [:post] # YES POST, because we don't want to log get variables here
  match 'api/v1/admin/network/search' => 'api/patient_network#admin_search', as: :api_network_admin_search, via: [:get]


  #############################################################################
  #
  #     Web App Views and Stuffs
  #
  #############################################################################

  match 'webhooks/stripe' => 'webhooks#stripe', via: [:post]
  match 'webhooks/twilio/voice' => 'webhooks#twilio_voice', via: [:post]
  match 'webhooks/twilio/sms' => 'webhooks#twilio_sms', via: [:post]

  match 'lsqr' => 'lifesquares#lsqr_home', via: [:get]
  # TODO: WTF SON
  match 'lsqr/:id' => 'lifesquares#lsqr_qrscan', via: [:get]
  match 'LSQR/:id' => 'lifesquares#lsqr_qrscan', via: [:get]

  # this is potential trainwreck twerkers
  devise_for :accounts, :skip => [:sessions], :controllers => { :registrations => 'registrations' }

  devise_scope :account do
    # existing portal devise stuffs
    match 'login' => 'devise/sessions#new', :as => :login, via: [:get]
    match 'login' => 'devise/sessions#new', :as => :new_account_session, via: [:get] # well then, we did skip it above :)
    match 'login' => 'devise/sessions#create', :as => :do_login, via:[:post]
    match 'logout' => 'devise/sessions#destroy', :as => :logout, via: [:delete]
    match 'signup' => 'devise/registrations#new', :as => :create_account, via: [:get] # route name?? signup? lol
    match 'signup/choose' => 'accounts#signup_choose', :as => :signup_choose, via: [:get]
    match 'signup/business' => 'accounts#signup_enterprise', :as => :signup_enterprise, via: [:get]
    match 'account/edit' => 'devise/registrations#edit', :as => :edit_account, via: [:get]
    # accounts/password/new
    match 'recover-account' => 'devise/passwords#new', :as => :recover_account, via: [:get]
    match 'confirm-account' => 'devise/confirmations#new', :as => :confirm_account, via: [:get]

    # the entry url for processing inbound from email or whateves
    # get 'resend-confirmation' => 
    # rewire the forgot password stuffs son

    # TODO: really want to move these
    
  end

  # SSO
  devise_scope :sso do
    match 'sso/pingone' => 'sso#pingone', :as => :sso_pingone, via: [:post]
  end

  match 'account/provider-credentials' => 'provider#register', :as => :account_provider_register, via: [:get]
  match 'account/save-signup-refer' => 'accounts#save_signup_refer', :as => :account_save_signup_refer, via: [:put]
  match 'account/terms-update' => 'accounts#terms_update', :as => :account_terms_update, via: [:get, :post]
  match 'account/email-friend' => 'accounts#email_friend', :as => :account_email_friend, via: [:post] # TO api? at some point, lol
  match 'account/tell-a-friend' => 'accounts#tellafriend', :as => :account_tell_a_friend, :via => [:get]

  # do these belong in "account"
  match 'lifesquares/assign' => 'lifesquares#show_assign', :as => :lifesquares_show_assign, via: [:get]
  match 'lifesquares/renew' => 'lifesquares#show_renew', :as => :lifesquares_show_renew, via: [:get]
  match 'lifesquares/replace' => 'lifesquares#show_replace', :as => :lifesquares_show_replace, via: [:get]

  # TODO: we're conflicting with the resource API definition for :patients UGGG
  match 'profiles' => 'patients#index', :as => :patient_index, via: [:get] # this should have already been mapped, wtf
  match 'profiles/new' => 'patients#new', :as => :patient_new, via: [:get] # this should have already been mapped, wtf
  match 'profiles/:uuid' => 'patients#show', :as => :patient_show, via: [:get]
  match 'profiles/:uuid/continue-setup' => 'patients#continue_setup', :as => :patient_continue_setup, via: [:get]
  match 'profiles/:uuid/confirm' => 'patients#confirm', :as => :patient_confirm, :confirm => true, via: [:get]
  match 'profiles/:uuid/finish-confirmation' => 'patients#finish_confirmation', :as => :patient_finish_confirmation, via: [:get]
  match 'profiles/:uuid/confirm-and-create' => 'patients#finish_confirmation', :create => true, :as => :patient_confirm_and_create, via: [:get]
  match 'profiles/:uuid/setup-complete' => 'patients#setup_complete', :as => :patient_setup_complete, via: [:get]
  match 'profiles/:uuid/edit-personal' => 'patients#edit_personal', :as => :patient_edit_personal, via: [:get]
  match 'profiles/:uuid/edit-medical' => 'patients#edit_medical', :as => :patient_edit_medical, via: [:get]
  match 'profiles/:uuid/edit-contacts' => 'patients#edit_contacts', :as => :patient_edit_contacts, via: [:get]
  match 'profiles/:uuid/notify-emergency-contacts' => 'patients#edit_emergency_contacts', :as => :patient_edit_emergency_contacts, via: [:get]
  match 'profiles/:uuid/webview/:privacy' => 'patients#show_webview', :as => :patient_show_webview, via: [:get]
  match 'profiles/:uuid/network/shared-with-you' => 'patients#show_network_inbound', :as => :patient_show_network_inbound, via: [:get]
  match 'profiles/:uuid/network/you-have-shared' => 'patients#show_network_outbound', :as => :patient_show_network_outbound, via: [:get]
  match 'profiles/:uuid/network' => 'patients#show_network', :as => :patient_show_network, via: [:get]

  match 'profiles/:uuid/advise-me' => 'care_plans#patient_show', :as => 'care_plans_patient', via: [:get]
  match 'profiles/:uuid/advise-me/:care_plan_uuid' => 'care_plans#care_plan', :as => 'care_plans_care_plan', via: [:get] # meh, this is really placeholder
  match 'profiles/:uuid/advise-me/:care_plan_uuid/advice/:recommendation_uuid' => 'care_plans#advice', :as => 'care_plans_advice', via: [:get]
  match 'profiles/:uuid/advise-me/:care_plan_uuid/:question_group_uuid' => 'care_plans#question_group', :as => 'care_plans_question_group', via: [:get]
  
  match 'advise-me' => 'care_plans#index', :as => 'care_plans_index', via: [:get]

  # so lonely
  match 'documents/:uuid' => 'documents#show', :as => :document_show, via: [:get]
  # lonely out here
  match 'network/pending-requests' => 'patient_network#show_all_pending_invites', :as => :network_show_all_pending_invites, :via => [:get]
  match 'network/:granter_patient_uuid/:auditor_patient_uuid/webview' => 'patients#show_webview_network', :as => :network_webview, via: [:get]
  
  match 'campaigns/:uuid' => 'campaigns#show', :as => :campaign_show, via: [:get]

  match 'orgs/:uuid' => 'organizations#show', :as => :organization_show, via: [:get]
  match 'orgs/:uuid/checkout/invoice/:invoice_uuid/' => 'organizations#invoice', :as => :organization_invoice, via: [:get]
  match 'orgs/:uuid/checkout/renew' => 'organizations#renew', :as => :organization_renew, via: [:get]
  match 'orgs/:uuid/checkout/lifesquares' => 'organizations#order_lifesquares', :as => :organization_order_lifesquares, via: [:get]


  #############################################################################
  #
  #     Cruddy™ Admin built in-house to replace rails admin and active admin
  #
  #############################################################################

  match 'admin' => 'admin#index', via: [:get], :as => :admin_index
  # resource definition? meh
  match 'admin/batches' => 'admin#batches_index' , via: [:get], :as => :admin_batch_index
  match 'admin/batches' => 'admin#batches_create', via: [:post], :as => :admin_batch_create
  match 'admin/batches/new' => 'admin#batches_new', via: [:get], :as => :admin_batch_new
  match 'admin/batches/:id' => 'admin#batches_show', via: [:get], :as => :admin_batch_show
  # resource definition? meh
  match 'admin/campaigns' => 'admin#campaigns_index' , via: [:get], :as => :admin_campaign_index
  match 'admin/campaigns' => 'admin#campaigns_create', via: [:post], :as => :admin_campaign_create
  match 'admin/campaigns/new' => 'admin#campaigns_new', via: [:get], :as => :admin_campaign_new
  match 'admin/campaigns/:id' => 'admin#campaigns_show', via: [:get], :as => :admin_campaign_show
  match 'admin/campaigns/:id' => 'admin#campaigns_update', via: [:post, :put], :as => :admin_campaign_update
  match 'admin/campaigns/:id' => 'admin#campaigns_destroy', via: [:delete], :as => :admin_campaign_destroy
  match 'admin/campaigns/:id/edit' => 'admin#campaigns_edit', via: [:get], :as => :admin_campaign_edit
  # resource definition? meh
  match 'admin/code_sheets' => 'admin#code_sheets_index' , via: [:get], :as => :admin_code_sheet_index
  match 'admin/code_sheets' => 'admin#code_sheets_create', via: [:post], :as => :admin_code_sheet_create
  match 'admin/code_sheets/new' => 'admin#code_sheets_new', via: [:get], :as => :admin_code_sheet_new
  match 'admin/code_sheets/:id' => 'admin#code_sheets_show', via: [:get], :as => :admin_code_sheet_show
  # meh
  match 'admin/organizations' => 'admin#organizations_index' , via: [:get], :as => :admin_organization_index
  match 'admin/organizations' => 'admin#organizations_create', via: [:post], :as => :admin_organization_create
  match 'admin/organizations/new' => 'admin#organizations_new', via: [:get], :as => :admin_organization_new
  match 'admin/organizations/:id' => 'admin#organizations_show', via: [:get], :as => :admin_organization_show
  match 'admin/organizations/:id' => 'admin#organizations_update', via: [:post], :as => :admin_organization_update
  match 'admin/organizations/:id/edit' => 'admin#organizations_edit', via: [:get], :as => :admin_organization_edit
  # meh meh
  match 'admin/invoices' => 'admin#invoices_index' , via: [:get], :as => :admin_invoice_index
  match 'admin/invoices' => 'admin#invoices_create' , via: [:post], :as => :admin_invoice_create
  match 'admin/invoices/new' => 'admin#invoices_new', via: [:get], :as => :admin_invoice_new
  match 'admin/invoices/:id' => 'admin#invoices_update', via: [:post], :as => :admin_invoice_update
  match 'admin/invoices/:id/edit' => 'admin#invoices_edit', via: [:get], :as => :admin_invoice_edit
  # meh
  match 'admin/provider_credentials' => 'admin#provider_credentials_index' , via: [:get], :as => :admin_provider_credentials_index
  match 'admin/provider_credentials/:id' => 'admin#provider_credentials_show' , via: [:get], :as => :admin_provider_credentials_show
  # double duty meh
  match 'admin/accounts' => 'admin#accounts_index' , via: [:get], :as => :admin_account_index
  # careplans TBD resource, etc bla
  match 'admin/care_plans' => 'admin#care_plans_index' , via: [:get], :as => :admin_care_plan_index
  match 'admin/care_plans/new' => 'admin#care_plans_designer', via: [:get], :as => :admin_care_plan_new
  match 'admin/care_plans/:id' => 'admin#care_plans_designer', via: [:get], :as => :admin_care_plan_show
  match 'admin/care_plans/(:id)' => 'admin#care_plans_update', via: [:post], :as => :admin_care_plan_update

  # network hacky bits
  match 'admin/patient-network' => 'admin#patient_network_create', via: [:post], :as => :admin_patient_network_create
  match 'admin/patient-network/new' => 'admin#patient_network_new', via: [:get], :as => :admin_patient_network_new

  match 'admin/notification/scan-email' => 'admin#debug_notification_scan_email', via: [:get], :as => :admin_debug_notification_scan_email
  match 'admin/notification/scansms-email' => 'admin#debug_notification_scansms_email', via: [:get], :as => :admin_debug_notification_scansms_email

  # match 'admin/question_groups' => 'admin#question_groups_index' , via: [:get], :as => :admin_question_group_index
  # match 'admin/question_groups/new' => 'admin#question_groups_new' , via: [:get], :as => :admin_question_group_new
  # match 'admin/question_groups/:id' => 'admin#question_groups_show', via: [:get], :as => :admin_question_group_show

  # questions
  # match 'admin/questions' => 'admin#questions_index' , via: [:get], :as => :admin_question_index

  # choices
  # match 'admin/choices' => 'admin#choices_index' , via: [:get], :as => :admin_choice_index

  # recommendations
  match 'admin/recommendations' => 'admin#recommendations_index' , via: [:get], :as => :admin_recommendation_index

  # hehe
  match 'admin/styleguide' => 'admin#styleguide' , via: [:get], :as => :admin_styleguide
  
end
