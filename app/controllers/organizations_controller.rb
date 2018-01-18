class OrganizationsController < ApplicationController
    before_action :authenticate_account!
    before_action :obtain_organization
    # before_action :require_organization_permissions, break it out bro

    def show

    end

    def invite
        # the form for inviting a user? if it needs this standalone, it should probably be js in modal on the show screen lol lol
    end

    def renew
        @coverage_end = Date.today + 365
        @cards_on_file = current_account.get_available_cards()
        @publishable_key = Rails.configuration.stripe[:publishable_key]
        @total = @organization.get_coverage_cost() * @organization.get_membership_count()
    end

    def order_lifesquares
        @unit_cost = @organization.get_coverage_cost()
        @total = 0
        @coverage_start = Date.today
        @coverage_end = Date.today + 365
        @cards_on_file = current_account.get_available_cards()
        @publishable_key = Rails.configuration.stripe[:publishable_key]
    end

    def invoice
        @invoice = Invoice.where(:uuid=>params[:invoice_uuid]).first
        # keep it classy bro
        @cards_on_file = current_account.get_available_cards()
        @publishable_key = Rails.configuration.stripe[:publishable_key]
    end

end