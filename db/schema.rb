# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170925203448) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "account", primary_key: "account_id", force: :cascade do |t|
    t.string   "email",                  limit: 100,               default: "",   null: false
    t.string   "encrypted_password",     limit: 128,               default: "",   null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at",             precision: 6
    t.datetime "remember_created_at",                precision: 6
    t.integer  "sign_in_count",                                    default: 0
    t.datetime "current_sign_in_at",                 precision: 6
    t.datetime "last_sign_in_at",                    precision: 6
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at",                       precision: 6
    t.datetime "confirmation_sent_at",               precision: 6
    t.integer  "failed_attempts",                                  default: 0
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at",                          precision: 6
    t.string   "account_type",           limit: 10,                               null: false
    t.string   "account_status",         limit: 10,                               null: false
    t.integer  "create_user",                                                     null: false
    t.datetime "create_date",                        precision: 6,                null: false
    t.integer  "update_user",                                                     null: false
    t.datetime "last_update",                        precision: 6,                null: false
    t.string   "signup_refer",           limit: 10
    t.bigint   "campaign_id"
    t.string   "payment_type",           limit: 10
    t.string   "payment_card_number",    limit: 30
    t.datetime "payment_card_exp",                   precision: 6
    t.string   "payment_card_name",      limit: 75
    t.string   "payment_card_addr1",     limit: 75
    t.string   "payment_card_sc",        limit: 10
    t.boolean  "optin_email_marketing",                            default: true, null: false
    t.string   "unconfirmed_email",      limit: 100
    t.string   "terms_of_use",           limit: 10
    t.string   "authentication_token",   limit: 255
    t.string   "uid",                    limit: 255
    t.string   "stripe_customer_id"
    t.string   "signup_platform",        limit: 30
    t.string   "mobile_phone"
    t.text     "exit_survey"
    t.index ["authentication_token"], name: "index_account_on_authentication_token", using: :btree
    t.index ["confirmation_token"], name: "altered_account_conf_token_uk", unique: true, using: :btree
    t.index ["email"], name: "account_email_key", unique: true, using: :btree
    t.index ["email"], name: "altered_account_email_uk", unique: true, using: :btree
    t.index ["reset_password_token"], name: "altered_account_reset_pt_uk", unique: true, using: :btree
    t.index ["uid"], name: "index_account_on_uid", unique: true, using: :btree
    t.index ["unlock_token"], name: "altered_account_unlock_token_uk", unique: true, using: :btree
  end

  create_table "account_device", primary_key: "account_device_id", force: :cascade do |t|
    t.integer  "account_id",                                               null: false
    t.string   "device_token",                                             null: false
    t.string   "client_version"
    t.string   "client_build"
    t.string   "platform",                                                 null: false
    t.uuid     "uuid",               default: -> { "uuid_generate_v4()" }, null: false
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.integer  "notification_count", default: 0
    t.string   "endpoint_arn"
    t.index ["account_id"], name: "index_account_device_on_account_id", using: :btree
    t.index ["uuid"], name: "index_account_device_on_uuid", unique: true, using: :btree
  end

  create_table "account_location", primary_key: "account_location_id", force: :cascade do |t|
    t.integer  "account_id", null: false
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_location_on_account_id", unique: true, using: :btree
  end

  create_table "account_organization", primary_key: "account_organization_id", force: :cascade do |t|
    t.integer  "account_id",                         null: false
    t.integer  "organization_id",                    null: false
    t.string   "role",            default: "MEMBER", null: false
    t.string   "status",          default: "ACTIVE", null: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.index ["account_id"], name: "index_account_organization_on_account_id", using: :btree
    t.index ["organization_id"], name: "index_account_organization_on_organization_id", using: :btree
  end

  create_table "account_token", primary_key: "account_token_id", force: :cascade do |t|
    t.string   "token"
    t.integer  "account_device_id"
    t.integer  "account_id"
    t.datetime "expires_at"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.index ["account_device_id"], name: "index_account_token_on_account_device_id", using: :btree
    t.index ["account_id"], name: "index_account_token_on_account_id", using: :btree
    t.index ["token"], name: "index_account_token_on_token", using: :btree
  end

  create_table "active_admin_comments", primary_key: "admin_note_id", force: :cascade do |t|
    t.integer  "resource_id",                             null: false
    t.string   "resource_type", limit: 255,               null: false
    t.integer  "author_id"
    t.string   "author_type",   limit: 255
    t.text     "body"
    t.datetime "created_at",                precision: 6
    t.datetime "updated_at",                precision: 6
    t.string   "namespace",     limit: 255
    t.index ["author_type", "author_id"], name: "i_act_adm_com_aut_typ_aut_id", using: :btree
    t.index ["namespace"], name: "i_act_adm_com_nam", using: :btree
    t.index ["resource_type", "resource_id"], name: "i_adm_not_res_typ_res_id", using: :btree
  end

  create_table "admin_user", primary_key: "admin_user_id", force: :cascade do |t|
    t.string   "email",                  limit: 255,               default: "", null: false
    t.string   "encrypted_password",     limit: 128,               default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at",             precision: 6
    t.datetime "remember_created_at",                precision: 6
    t.integer  "sign_in_count",                                    default: 0
    t.datetime "current_sign_in_at",                 precision: 6
    t.datetime "last_sign_in_at",                    precision: 6
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                         precision: 6
    t.datetime "updated_at",                         precision: 6
    t.index ["email"], name: "index_admin_user_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "i_adm_use_res_pas_tok", unique: true, using: :btree
  end

  create_table "audit", primary_key: "audit_id", force: :cascade do |t|
    t.integer  "scanner_account_id"
    t.string   "lifesquare",           limit: 255
    t.text     "content"
    t.boolean  "is_provider"
    t.boolean  "is_owner"
    t.string   "privacy",              limit: 255
    t.datetime "created_at",                       precision: 6,                    null: false
    t.datetime "updated_at",                       precision: 6,                    null: false
    t.float    "latitude"
    t.float    "longitude"
    t.string   "ip",                   limit: 15
    t.string   "platform",             limit: 10,                default: "mobile"
    t.string   "scanner_phone_number"
  end

  create_table "campaign", primary_key: "campaign_id", force: :cascade do |t|
    t.integer  "create_user",                                                                                    null: false
    t.datetime "create_date",                                precision: 6,                                       null: false
    t.integer  "update_user",                                                                                    null: false
    t.datetime "last_update",                                precision: 6,                                       null: false
    t.string   "name",                          limit: 30,                                                       null: false
    t.string   "description",                   limit: 1000
    t.datetime "start_date",                                 precision: 6
    t.datetime "end_date",                                   precision: 6
    t.integer  "organization_id"
    t.integer  "start_up_fee",                                             default: 0
    t.integer  "price_per_lifesquare_per_year",                            default: 0
    t.date     "renewal_date"
    t.integer  "campaign_status",                                          default: 1
    t.integer  "user_shared_cost_for_campaign",                            default: 0
    t.text     "stripe_plan_key"
    t.string   "promo_code",                    limit: 255
    t.integer  "promo_price",                                              default: 0
    t.date     "promo_start_date"
    t.date     "promo_end_date"
    t.uuid     "uuid",                                                     default: -> { "uuid_generate_v4()" }
    t.integer  "lifesquare_credits",                                       default: 0
    t.boolean  "requires_shipping",                                        default: true
    t.text     "post_signup_memo"
    t.text     "pre_signup_memo"
    t.index ["uuid"], name: "index_campaign_on_uuid", unique: true, using: :btree
  end

  create_table "care_plan", primary_key: "care_plan_id", force: :cascade do |t|
    t.integer  "organization_id"
    t.string   "name",                                                  null: false
    t.string   "description",                                           null: false
    t.string   "status",          default: "DRAFT",                     null: false
    t.json     "filters"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid     "uuid",            default: -> { "uuid_generate_v4()" }
    t.index ["organization_id"], name: "index_care_plan_on_organization_id", using: :btree
    t.index ["uuid"], name: "index_care_plan_on_uuid", unique: true, using: :btree
  end

  create_table "care_plan_question", primary_key: "care_plan_question_id", force: :cascade do |t|
    t.integer  "care_plan_question_group_id"
    t.string   "name",                                                              null: false
    t.string   "description"
    t.string   "active",                      default: "ACTIVE",                    null: false
    t.integer  "position"
    t.string   "text"
    t.string   "choice_type",                                                       null: false
    t.string   "input_type",                  default: "RADIO",                     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid     "uuid",                        default: -> { "uuid_generate_v4()" }
    t.index ["care_plan_question_group_id"], name: "index_care_plan_question_on_care_plan_question_group_id", using: :btree
    t.index ["uuid"], name: "index_care_plan_question_on_uuid", unique: true, using: :btree
  end

  create_table "care_plan_question_choice", primary_key: "care_plan_question_choice_id", id: :integer, default: -> { "nextval('care_plan_question_choice_care_plan_question_response_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer  "care_plan_question_id"
    t.string   "name",                                                                   null: false
    t.string   "description"
    t.string   "active",                           default: "ACTIVE",                    null: false
    t.integer  "position"
    t.string   "text"
    t.string   "value_expression"
    t.integer  "next_care_plan_question_group_id"
    t.integer  "next_care_plan_recommendation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid     "uuid",                             default: -> { "uuid_generate_v4()" }
    t.index ["care_plan_question_id"], name: "index_care_plan_question_choice_on_care_plan_question_id", using: :btree
    t.index ["uuid"], name: "index_care_plan_question_choice_on_uuid", unique: true, using: :btree
  end

  create_table "care_plan_question_group", primary_key: "care_plan_question_group_id", force: :cascade do |t|
    t.integer  "care_plan_id"
    t.string   "name",                                               null: false
    t.string   "description"
    t.string   "active",       default: "ACTIVE",                    null: false
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid     "uuid",         default: -> { "uuid_generate_v4()" }
    t.index ["care_plan_id"], name: "index_care_plan_question_group_on_care_plan_id", using: :btree
    t.index ["uuid"], name: "index_care_plan_question_group_on_uuid", unique: true, using: :btree
  end

  create_table "care_plan_recommendation", primary_key: "care_plan_recommendation_id", force: :cascade do |t|
    t.integer  "care_plan_id"
    t.string   "name",                                               null: false
    t.string   "description"
    t.string   "active",       default: "ACTIVE",                    null: false
    t.string   "text",                                               null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid     "uuid",         default: -> { "uuid_generate_v4()" }
    t.index ["care_plan_id"], name: "index_care_plan_recommendation_on_care_plan_id", using: :btree
    t.index ["uuid"], name: "index_care_plan_recommendation_on_uuid", unique: true, using: :btree
  end

  create_table "care_plan_response", primary_key: "care_plan_response_id", force: :cascade do |t|
    t.integer  "care_plan_id",                                       null: false
    t.string   "session_id",                                         null: false
    t.integer  "patient_id",                                         null: false
    t.uuid     "uuid",         default: -> { "uuid_generate_v4()" }
    t.string   "active",       default: "ACTIVE",                    null: false
    t.json     "care_plan"
    t.json     "response"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["care_plan_id", "session_id"], name: "index_care_plan_response_on_care_plan_id_and_session_id", unique: true, using: :btree
    t.index ["patient_id"], name: "index_care_plan_response_on_patient_id", using: :btree
    t.index ["uuid"], name: "index_care_plan_response_on_uuid", unique: true, using: :btree
  end

  create_table "code_sheet_print_request", primary_key: "code_sheet_print_request_id", force: :cascade do |t|
    t.integer  "status",                                          default: 0
    t.integer  "priority"
    t.date     "mailed_at"
    t.string   "address_line1",         limit: 150
    t.string   "address_line2",         limit: 100
    t.string   "address_line3",         limit: 100
    t.string   "city",                  limit: 50
    t.string   "state_province",        limit: 50
    t.string   "country",               limit: 2
    t.string   "postal_code",           limit: 15
    t.datetime "created_at",                        precision: 6
    t.datetime "updated_at",                        precision: 6
    t.boolean  "reprint",                                         default: false
    t.text     "lifesquares"
    t.text     "print_data"
    t.integer  "sheets_per_lifesquare",                           default: 3
    t.text     "instructions"
  end

  create_table "coverage", primary_key: "coverage_id", force: :cascade do |t|
    t.integer  "patient_id",                                                           null: false
    t.date     "coverage_start"
    t.date     "coverage_end"
    t.integer  "payment_id"
    t.boolean  "recurring",                                         default: false
    t.string   "coverage_status",         limit: 255,               default: "ACTIVE"
    t.datetime "created_at",                          precision: 6,                    null: false
    t.datetime "updated_at",                          precision: 6,                    null: false
    t.text     "stripe_subscription_key"
    t.integer  "sticker_credits",                                   default: 0
  end

  create_table "document_digitized", primary_key: "document_digitized_id", force: :cascade do |t|
    t.string   "category",    limit: 255
    t.string   "title",       limit: 255
    t.string   "description", limit: 255
    t.datetime "created_at",              precision: 6, null: false
    t.datetime "updated_at",              precision: 6, null: false
  end

  create_table "document_digitized_file", primary_key: "document_digitized_file_id", force: :cascade do |t|
    t.integer  "document_digitized_id",                           null: false
    t.integer  "part_number"
    t.string   "file_format",           limit: 255
    t.string   "file_spec",             limit: 255
    t.datetime "created_at",                        precision: 6, null: false
    t.datetime "updated_at",                        precision: 6, null: false
    t.string   "digitized_file_uid",    limit: 250
    t.index ["document_digitized_id"], name: "index_document_digitized_file_on_document_digitized_id", using: :btree
  end

  create_table "imo_med_generic_name", id: false, force: :cascade do |t|
    t.string "med_name",     limit: 300, null: false
    t.string "generic_name", limit: 500, null: false
    t.index ["med_name", "generic_name"], name: "imo_med_generic_name_pk", unique: true, using: :btree
  end

  create_table "imo_med_name_strength_form", id: false, force: :cascade do |t|
    t.string "med_name",      limit: 300, null: false
    t.string "strength_form", limit: 500, null: false
    t.index ["med_name"], name: "imo_med_name_strength_form_med_name_idx", using: :btree
  end

  create_table "invoice", primary_key: "invoice_id", force: :cascade do |t|
    t.integer  "organization_id",                                       null: false
    t.uuid     "uuid",            default: -> { "uuid_generate_v4()" }, null: false
    t.integer  "payment_id"
    t.integer  "account_id"
    t.integer  "amount"
    t.string   "title"
    t.text     "description"
    t.text     "notes"
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.date     "due_date"
  end

  create_table "lifesquare", id: false, force: :cascade do |t|
    t.string   "lifesquare_uid",     limit: 9,                             null: false
    t.integer  "create_user",                                              null: false
    t.datetime "create_date",                    precision: 6,             null: false
    t.integer  "update_user",                                              null: false
    t.datetime "last_update",                    precision: 6,             null: false
    t.datetime "activation_date",                precision: 6
    t.integer  "patient_id"
    t.bigint   "campaign_id"
    t.integer  "valid_state",                                  default: 0
    t.string   "valid_state_setter", limit: 255
    t.integer  "record_order"
    t.integer  "batch_id"
    t.index ["patient_id"], name: "lifesquare_patient_idx", using: :btree
  end

  create_table "lifesquare_code_batch", primary_key: "lifesquare_code_batch_id", force: :cascade do |t|
    t.integer  "batch_size"
    t.string   "notes",      limit: 255
    t.datetime "created_at",             precision: 6
    t.datetime "updated_at",             precision: 6
  end

  create_table "log_event", id: false, force: :cascade do |t|
    t.string "log_event", limit: 255
    t.string "user_mask", limit: 50,  null: false
  end

  create_table "organization", primary_key: "organization_id", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.string   "contact_last_name",  limit: 255
    t.string   "contact_first_name", limit: 255
    t.string   "contact_salutation", limit: 255
    t.string   "contact_title",      limit: 255
    t.string   "contact_email",      limit: 255
    t.string   "contact_phone",      limit: 255
    t.datetime "created_at",                     precision: 6,                                       null: false
    t.datetime "updated_at",                     precision: 6,                                       null: false
    t.string   "ls_name",            limit: 15
    t.uuid     "uuid",                                         default: -> { "uuid_generate_v4()" }
    t.string   "slug",               limit: 32
    t.index ["uuid"], name: "index_organization_on_uuid", unique: true, using: :btree
  end

  create_table "patient", primary_key: "patient_id", force: :cascade do |t|
    t.integer  "create_user",                                                                                 null: false
    t.datetime "create_date",                             precision: 6,                                       null: false
    t.integer  "update_user",                                                                                 null: false
    t.datetime "last_update",                             precision: 6,                                       null: false
    t.date     "birthdate",                                                                                   null: false
    t.string   "first_name",                 limit: 50,                                                       null: false
    t.string   "last_name",                  limit: 50,                                                       null: false
    t.string   "middle_name",                limit: 50
    t.string   "patient_uid_country",        limit: 30
    t.string   "patient_uid_country_origin", limit: 2
    t.string   "patient_uid_state",          limit: 30
    t.string   "patient_uid_state_origin",   limit: 50
    t.string   "notes",                      limit: 4000
    t.string   "photo_uid",                  limit: 250
    t.string   "name_prefix",                limit: 50
    t.string   "name_suffix",                limit: 50
    t.string   "gender",                     limit: 20
    t.string   "eye_color_both",             limit: 30
    t.string   "eye_color_left",             limit: 30
    t.string   "eye_color_right",            limit: 30
    t.float    "weight"
    t.float    "height"
    t.date     "weight_measurement_date"
    t.date     "height_measurement_date"
    t.string   "hair_color",                 limit: 30
    t.string   "ethnicity",                  limit: 10
    t.date     "photo_date"
    t.string   "photo_thumb_crop_params",    limit: 30
    t.string   "preferred_name",             limit: 50
    t.date     "maternity_due_date"
    t.string   "medication_presence",        limit: 1
    t.string   "allergy_presence",           limit: 1
    t.string   "condition_presence",         limit: 1
    t.string   "procedure_presence",         limit: 1
    t.string   "directive_presence",         limit: 1
    t.boolean  "confirmed",                                             default: false
    t.string   "maternity_state",            limit: 1
    t.string   "maternity_due_date_mask",    limit: 20
    t.string   "photo640x640_uid",           limit: 250
    t.string   "photo138x138_uid",           limit: 250
    t.boolean  "organ_donor"
    t.string   "demographics_privacy",       limit: 20,                 default: "public",                    null: false
    t.string   "biometrics_privacy",         limit: 20,                 default: "public",                    null: false
    t.boolean  "searchable",                                            default: true
    t.string   "immunization_presence",      limit: 1,                  default: ""
    t.integer  "bp_systolic"
    t.integer  "bp_diastolic"
    t.integer  "pulse"
    t.uuid     "uuid",                                                  default: -> { "uuid_generate_v4()" }, null: false
    t.integer  "account_id",                                                                                  null: false
    t.string   "status",                                                default: "ACTIVE"
    t.string   "blood_type",                 limit: 10
    t.index ["uuid"], name: "index_patient_on_uuid", unique: true, using: :btree
  end

  create_table "patient_allergy", primary_key: "patient_allergy_id", force: :cascade do |t|
    t.integer  "patient_id",                                                        null: false
    t.integer  "create_user",                                                       null: false
    t.datetime "create_date",                      precision: 6,                    null: false
    t.integer  "update_user",                                                       null: false
    t.datetime "last_update",                      precision: 6,                    null: false
    t.datetime "start_date",                       precision: 6
    t.datetime "end_date",                         precision: 6
    t.string   "health_event_scope",  limit: 10
    t.string   "allergy_cause_notes", limit: 2000
    t.integer  "record_order"
    t.string   "allergen",            limit: 300,                                   null: false
    t.string   "reaction",            limit: 300
    t.string   "privacy",             limit: 20,                 default: "public", null: false
    t.string   "imo_code",            limit: 255
    t.string   "icd9_code",           limit: 255
    t.string   "icd10_code",          limit: 255
  end

  create_table "patient_care_provider", primary_key: "patient_care_provider_id", force: :cascade do |t|
    t.integer  "patient_id",                                                         null: false
    t.integer  "create_user",                                                        null: false
    t.datetime "create_date",                       precision: 6,                    null: false
    t.integer  "record_order"
    t.integer  "update_user",                                                        null: false
    t.datetime "last_update",                       precision: 6,                    null: false
    t.string   "first_name",            limit: 50
    t.string   "phone1",                limit: 30
    t.string   "phone2",                limit: 30
    t.string   "email",                 limit: 100
    t.string   "address_line1",         limit: 150
    t.string   "city",                  limit: 50
    t.string   "state_province",        limit: 50
    t.string   "country",               limit: 2
    t.string   "postal_code",           limit: 15
    t.string   "address_line2",         limit: 100
    t.string   "address_line3",         limit: 100
    t.string   "title",                 limit: 50
    t.string   "care_provider_class",   limit: 10
    t.string   "last_name",             limit: 50,                                   null: false
    t.string   "middle_name",           limit: 50
    t.string   "medical_facility_name", limit: 100
    t.string   "privacy",               limit: 20,                default: "public", null: false
  end

  create_table "patient_contact", primary_key: "patient_contact_id", force: :cascade do |t|
    t.integer  "patient_id",                                                         null: false
    t.integer  "create_user",                                                        null: false
    t.datetime "create_date",                       precision: 6,                    null: false
    t.integer  "update_user",                                                        null: false
    t.datetime "last_update",                       precision: 6,                    null: false
    t.string   "contact_relationship",  limit: 25
    t.string   "first_name",            limit: 100,                                  null: false
    t.string   "home_phone",            limit: 30,                                   null: false
    t.string   "mobile_phone",          limit: 30
    t.string   "work_phone",            limit: 30
    t.string   "email",                 limit: 100
    t.string   "address_line1",         limit: 150
    t.string   "city",                  limit: 50
    t.string   "state_province",        limit: 50
    t.string   "country",               limit: 2
    t.string   "postal_code",           limit: 15
    t.string   "address_line2",         limit: 100
    t.string   "address_line3",         limit: 100
    t.boolean  "next_of_kin"
    t.boolean  "power_of_attorney"
    t.integer  "record_order"
    t.string   "last_name",             limit: 100,                                  null: false
    t.datetime "list_advise_send_date",             precision: 6
    t.string   "privacy",               limit: 20,                default: "public", null: false
    t.boolean  "notification_postscan",                           default: true
  end

  create_table "patient_health_attribute", primary_key: "patient_health_attribute_id", force: :cascade do |t|
    t.integer  "patient_id",                                                          null: false
    t.integer  "create_user",                                                         null: false
    t.datetime "create_date",                        precision: 6,                    null: false
    t.integer  "update_user",                                                         null: false
    t.datetime "last_update",                        precision: 6,                    null: false
    t.string   "value",                 limit: 1024
    t.datetime "start_date",                         precision: 6
    t.datetime "end_date",                           precision: 6
    t.integer  "record_order"
    t.string   "privacy",               limit: 20,                 default: "public", null: false
    t.integer  "document_digitized_id"
  end

  create_table "patient_health_event", primary_key: "patient_health_event_id", force: :cascade do |t|
    t.integer  "patient_id",                                                         null: false
    t.integer  "create_user",                                                        null: false
    t.datetime "create_date",                       precision: 6,                    null: false
    t.integer  "update_user",                                                        null: false
    t.datetime "last_update",                       precision: 6,                    null: false
    t.datetime "start_date",                        precision: 6
    t.datetime "end_date",                          precision: 6
    t.string   "health_event_scope",    limit: 10
    t.string   "health_event_duration", limit: 255
    t.integer  "record_order"
    t.string   "health_event",          limit: 300,                                  null: false
    t.string   "health_event_type",     limit: 255,                                  null: false
    t.string   "start_date_mask",       limit: 20
    t.string   "privacy",               limit: 20,                default: "public", null: false
    t.string   "imo_code",              limit: 255
    t.string   "icd9_code",             limit: 255
    t.string   "icd10_code",            limit: 255
  end

  create_table "patient_insurance", primary_key: "patient_insurance_id", force: :cascade do |t|
    t.integer  "patient_id",                                                           null: false
    t.string   "policy_code",             limit: 30
    t.integer  "create_user",                                                          null: false
    t.datetime "create_date",                         precision: 6,                    null: false
    t.integer  "update_user",                                                          null: false
    t.datetime "last_update",                         precision: 6,                    null: false
    t.datetime "expire_date",                         precision: 6
    t.string   "group_code",              limit: 30
    t.string   "health_plan_code",        limit: 30
    t.datetime "effective_date",                      precision: 6
    t.string   "insurance_type",          limit: 10
    t.string   "policyholder_first_name", limit: 100
    t.integer  "record_order"
    t.string   "organization_name",       limit: 100,                                  null: false
    t.string   "policyholder_last_name",  limit: 100
    t.string   "phone",                   limit: 30
    t.string   "privacy",                 limit: 20,                default: "public", null: false
  end

  create_table "patient_language", primary_key: "patient_language_id", force: :cascade do |t|
    t.integer  "patient_id",                                    null: false
    t.string   "language_code",        limit: 2,                null: false
    t.string   "language_proficiency", limit: 10
    t.integer  "create_user",                                   null: false
    t.datetime "create_date",                     precision: 6, null: false
    t.integer  "record_order"
    t.index ["language_code", "patient_id"], name: "altered_patient_language_pk", unique: true, using: :btree
  end

  create_table "patient_medical_facility", primary_key: "patient_medical_facility_id", force: :cascade do |t|
    t.integer  "patient_id",                                                                 null: false
    t.string   "patient_medical_facility_stat", limit: 10
    t.integer  "create_user",                                                                null: false
    t.datetime "create_date",                               precision: 6,                    null: false
    t.integer  "record_order"
    t.integer  "update_user",                                                                null: false
    t.datetime "last_update",                               precision: 6,                    null: false
    t.string   "name",                          limit: 100,                                  null: false
    t.string   "phone",                         limit: 30
    t.string   "url",                           limit: 100
    t.string   "address_line1",                 limit: 150
    t.string   "city",                          limit: 50
    t.string   "state_province",                limit: 50
    t.string   "country",                       limit: 2
    t.string   "postal_code",                   limit: 15
    t.string   "address_line2",                 limit: 100
    t.string   "address_line3",                 limit: 100
    t.string   "medical_facility_type",         limit: 10,                                   null: false
    t.string   "privacy",                       limit: 20,                default: "public", null: false
  end

  create_table "patient_network", id: false, force: :cascade do |t|
    t.integer  "granter_patient_id",                                                        null: false
    t.integer  "auditor_patient_id",                                                        null: false
    t.boolean  "auditor_has_power_of_attorney"
    t.boolean  "auditor_is_family"
    t.datetime "created_at",                               precision: 6,                    null: false
    t.datetime "updated_at",                               precision: 6,                    null: false
    t.string   "privacy",                       limit: 20,               default: "public", null: false
    t.datetime "asked_at",                                 precision: 6
    t.datetime "joined_at",                                precision: 6
    t.text     "request_reason"
    t.boolean  "notification_postscan",                                  default: true
    t.datetime "expires_at"
    t.index ["auditor_patient_id"], name: "index_patient_network_on_auditor_patient_id", using: :btree
    t.index ["granter_patient_id"], name: "index_patient_network_on_granter_patient_id", using: :btree
  end

  create_table "patient_pharmacy", primary_key: "patient_pharmacy_id", force: :cascade do |t|
    t.integer  "patient_id",                                                  null: false
    t.integer  "create_user",                                                 null: false
    t.datetime "create_date",                precision: 6,                    null: false
    t.integer  "record_order"
    t.integer  "update_user",                                                 null: false
    t.datetime "last_update",                precision: 6,                    null: false
    t.string   "name",           limit: 100,                                  null: false
    t.string   "phone",          limit: 30
    t.string   "url",            limit: 100
    t.string   "address_line1",  limit: 150
    t.string   "city",           limit: 50
    t.string   "state_province", limit: 50
    t.string   "country",        limit: 2
    t.string   "postal_code",    limit: 15
    t.string   "address_line2",  limit: 100
    t.string   "address_line3",  limit: 100
    t.string   "privacy",        limit: 20,                default: "public", null: false
  end

  create_table "patient_residence", primary_key: "patient_residence_id", force: :cascade do |t|
    t.integer  "patient_id",                                                             null: false
    t.string   "residence_type",            limit: 10,                                   null: false
    t.integer  "create_user",                                                            null: false
    t.datetime "create_date",                           precision: 6,                    null: false
    t.integer  "update_user",                                                            null: false
    t.datetime "last_update",                           precision: 6,                    null: false
    t.string   "address_line1",             limit: 150,                                  null: false
    t.string   "city",                      limit: 50,                                   null: false
    t.string   "state_province",            limit: 50,                                   null: false
    t.string   "country",                   limit: 2
    t.string   "postal_code",               limit: 15,                                   null: false
    t.string   "address_line2",             limit: 100
    t.string   "address_line3",             limit: 100
    t.integer  "record_order"
    t.boolean  "mailing_address"
    t.string   "privacy",                   limit: 20,                default: "public", null: false
    t.string   "lifesquare_location_type",  limit: 255
    t.string   "lifesquare_location_other", limit: 30
    t.float    "latitude"
    t.float    "longitude"
  end

  create_table "patient_therapy", primary_key: "patient_therapy_id", force: :cascade do |t|
    t.integer  "patient_id",                                                          null: false
    t.string   "health_event_scope",    limit: 10
    t.integer  "create_user",                                                         null: false
    t.datetime "create_date",                        precision: 6,                    null: false
    t.integer  "update_user",                                                         null: false
    t.datetime "last_update",                        precision: 6,                    null: false
    t.datetime "start_date",                         precision: 6
    t.datetime "end_date",                           precision: 6
    t.string   "health_event_duration", limit: 10
    t.integer  "record_order"
    t.string   "therapy_frequency",     limit: 100
    t.string   "therapy_quantity",      limit: 100
    t.string   "therapy",               limit: 300,                                   null: false
    t.string   "therapy_strength_form", limit: 1000
    t.string   "privacy",               limit: 20,                 default: "public", null: false
    t.string   "imo_code",              limit: 255
    t.string   "icd9_code",             limit: 255
    t.string   "icd10_code",            limit: 255
  end

  create_table "payment", primary_key: "payment_id", force: :cascade do |t|
    t.integer  "account_id"
    t.integer  "patient_id"
    t.text     "description"
    t.string   "category",             limit: 255
    t.integer  "amount"
    t.string   "processor",            limit: 255,               default: "stripe"
    t.string   "processor_payment_id", limit: 255
    t.text     "processor_response"
    t.string   "origin",               limit: 255,               default: "CUSTOMER DIRECT ENTRY"
    t.datetime "created_at",                       precision: 6,                                   null: false
    t.datetime "updated_at",                       precision: 6,                                   null: false
  end

  create_table "provider_credential", primary_key: "provider_credential_id", force: :cascade do |t|
    t.integer  "patient_id",                                                             null: false
    t.boolean  "credentialed",                                           default: false
    t.string   "status",                       limit: 10,                                null: false
    t.date     "expiration",                                                             null: false
    t.string   "license_number",               limit: 50,                                null: false
    t.string   "licensing_state_province",     limit: 50
    t.string   "licensing_country",            limit: 2,                                 null: false
    t.text     "licensing_board",                                                        null: false
    t.string   "supervisor_name",              limit: 100,                               null: false
    t.string   "supervisor_contact_email",     limit: 100,                               null: false
    t.string   "supervisor_contact_phone",     limit: 30,                                null: false
    t.string   "supervisor_contact_phone_ext", limit: 30
    t.datetime "created_at",                               precision: 6,                 null: false
    t.datetime "updated_at",                               precision: 6,                 null: false
    t.integer  "document_digitized_id"
    t.index ["patient_id"], name: "index_provider_credential_on_patient_id", using: :btree
    t.index ["provider_credential_id"], name: "index_provider_credential_on_provider_credential_id", using: :btree
  end

  create_table "rails_admin_histories", primary_key: "rails_admin_history_id", force: :cascade do |t|
    t.text     "message"
    t.string   "username",   limit: 255
    t.integer  "item"
    t.string   "table",      limit: 255
    t.integer  "month",      limit: 2
    t.bigint   "year"
    t.datetime "created_at",             precision: 6
    t.datetime "updated_at",             precision: 6
    t.integer  "history_id"
  end

  create_table "scanner", id: false, force: :cascade do |t|
    t.string   "scanner_uid",           limit: 50,                             null: false
    t.bigint   "er_unit_id",                                                   null: false
    t.string   "scanner_type",          limit: 10,                             null: false
    t.string   "local_app_uid",         limit: 20,                             null: false
    t.string   "account_status",        limit: 10,                             null: false
    t.integer  "read_cnt",                                         default: 0, null: false
    t.datetime "read_cnt_period_start",              precision: 6,             null: false
    t.integer  "create_user",                                                  null: false
    t.datetime "create_date",                        precision: 6,             null: false
    t.integer  "update_user",                                                  null: false
    t.datetime "last_update",                        precision: 6,             null: false
    t.string   "notes",                 limit: 1000
    t.string   "telephone_number",      limit: 30
  end

  create_table "scanner_checkpoint", id: false, force: :cascade do |t|
    t.integer  "steward_scanner_patient_log_id",                            null: false
    t.bigint   "checkpoint_uid",                                            null: false
    t.datetime "create_date",                                 precision: 6, null: false
    t.datetime "client_send_date",                            precision: 6, null: false
    t.datetime "checkpoint_date",                             precision: 6, null: false
    t.string   "checkpoint_type",                limit: 30
    t.string   "function",                       limit: 1000
    t.bigint   "line"
    t.string   "message",                        limit: 4000
  end

  create_table "scanner_location", id: false, force: :cascade do |t|
    t.integer  "steward_scanner_patient_log_id",                           null: false
    t.datetime "create_date",                    precision: 6,             null: false
    t.datetime "client_send_date",               precision: 6,             null: false
    t.datetime "measure_date",                   precision: 6,             null: false
    t.decimal  "latitude",                       precision: 18, scale: 12, null: false
    t.decimal  "longitude",                      precision: 18, scale: 12, null: false
    t.decimal  "accuracy",                       precision: 9,  scale: 6,  null: false
    t.decimal  "speed",                          precision: 10, scale: 6,  null: false
  end

  create_table "scanner_type", id: false, force: :cascade do |t|
    t.string "scanner_type", limit: 255
    t.string "user_mask",    limit: 50,  null: false
  end

  create_table "steward", primary_key: "steward_id", force: :cascade do |t|
    t.string   "steward_type",               limit: 10,                             null: false
    t.string   "account_status",             limit: 10,                             null: false
    t.integer  "read_cnt",                                              default: 0, null: false
    t.datetime "read_cnt_period_start",                   precision: 6,             null: false
    t.integer  "create_user",                                                       null: false
    t.datetime "create_date",                             precision: 6,             null: false
    t.integer  "update_user",                                                       null: false
    t.datetime "last_update",                             precision: 6,             null: false
    t.string   "first_name",                 limit: 50,                             null: false
    t.string   "last_name",                  limit: 50,                             null: false
    t.datetime "birthdate",                               precision: 6,             null: false
    t.integer  "account_id",                                                        null: false
    t.string   "middle_name",                limit: 50
    t.string   "steward_uid_country",        limit: 30
    t.string   "steward_uid_country_origin", limit: 2
    t.string   "steward_uid_state",          limit: 30
    t.string   "steward_uid_state_origin",   limit: 50
    t.string   "permit_uid",                 limit: 50
    t.string   "notes",                      limit: 4000
    t.index ["account_id"], name: "steward_account_uk", unique: true, using: :btree
  end

  create_table "steward_scanner", id: false, force: :cascade do |t|
    t.bigint   "steward_id",                              null: false
    t.string   "scanner_uid",    limit: 50,               null: false
    t.string   "account_status", limit: 10,               null: false
    t.integer  "create_user",                             null: false
    t.datetime "create_date",               precision: 6, null: false
    t.integer  "update_user",                             null: false
    t.datetime "last_update",               precision: 6, null: false
  end

  create_table "steward_scanner_patient_log", primary_key: "steward_scanner_patient_log_id", force: :cascade do |t|
    t.datetime "create_date",                 precision: 6, null: false
    t.string   "log_event",        limit: 50,               null: false
    t.bigint   "steward_id"
    t.string   "scanner_uid",      limit: 50
    t.integer  "patient_id"
    t.integer  "account_id"
    t.string   "lifesquare_uid",   limit: 9
    t.string   "local_app_uid",    limit: 20
    t.string   "geo_coords",       limit: 20
    t.string   "code_capture",     limit: 10
    t.datetime "event_date",                  precision: 6
    t.datetime "client_send_date",            precision: 6
    t.text     "log_detail"
    t.text     "checkpoints"
  end

  create_table "steward_type", id: false, force: :cascade do |t|
    t.string "steward_type", limit: 255
    t.string "user_mask",    limit: 30,  null: false
  end

  add_foreign_key "account_device", "account", primary_key: "account_id"
  add_foreign_key "account_location", "account", primary_key: "account_id"
  add_foreign_key "account_organization", "account", primary_key: "account_id"
  add_foreign_key "account_organization", "organization", primary_key: "organization_id"
  add_foreign_key "care_plan", "organization", primary_key: "organization_id"
  add_foreign_key "care_plan_question", "care_plan_question_group", primary_key: "care_plan_question_group_id"
  add_foreign_key "care_plan_question_choice", "care_plan_question", primary_key: "care_plan_question_id"
  add_foreign_key "care_plan_question_group", "care_plan", primary_key: "care_plan_id"
  add_foreign_key "care_plan_recommendation", "care_plan", primary_key: "care_plan_id"
  add_foreign_key "care_plan_response", "care_plan", primary_key: "care_plan_id"
  add_foreign_key "care_plan_response", "patient", primary_key: "patient_id"
  add_foreign_key "patient", "account", primary_key: "account_id"
end
