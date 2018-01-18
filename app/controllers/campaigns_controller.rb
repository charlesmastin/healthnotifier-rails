class CampaignsController < ApplicationController

  def show
    # TODO: check if this is in the valid date window
    # determine details on the promo code, date window, pricing summary, etc
    @campaign = Campaign.where(:uuid=>params[:uuid], :campaign_status => 1).first
  end

end