class SsoController < ApplicationController
  before_action :authenticate_account!, :except => :pingone

  def pingone
    @tokenid = params[:tokenid]
    puts @tokenid
    @token_service_base_url = Rails.application.config.pingone[:token_service_base_url] 
    @url = URI.parse "#{@token_service_base_url}/sso/TXS/2.0/1/%s" % @tokenid
    @http = Net::HTTP.new(@url.host, @url.port)
    @http.use_ssl = true;
    @request = Net::HTTP::Get.new(@url.path)
    @rest_api_client_id = Rails.application.config.pingone[:rest_api_client_id]
    @rest_api_client_secret = Rails.application.config.pingone[:rest_api_client_secret] 
    @request.basic_auth @rest_api_client_id, @rest_api_client_secret
    @response = @http.request(@request)
    @data = JSON.parse @response.body
    @subject = @data['pingone.subject']
    @idpid = @data['pingone.idp.id']
    @account = Account.find_by_email_and_account_status(@subject, 'ACTIVE')
    if @account
      sign_in(:account, @account)
      redirect_to "/"
    else
      # TODO: include some campaign if for athenaNet
      redirect_to "/signup?email=#{@subject}"
    end
  end

end
