require 'json'

module Api
  class CodeSheetPrintRequestController < Api::ApplicationController
    before_action :authenticate_account
    before_action :require_lifesquare_employee

    def show
      # ok, it's a hack, for now, because I don't want the node implementation to have to parse new things
      cspr = CodeSheetPrintRequest.where(:code_sheet_print_request_id => params[:id]).first
      if cspr != nil
        # ensure we have the data son
        # manualy serialization son
        # validate
        render :json => JSON.parse(cspr.print_data), :status => 200
        return
      else
        render :json => {}, :status => 404
        return
      end
    end

    def download
      cspr = CodeSheetPrintRequest.where(:code_sheet_print_request_id => params[:id]).first
      if cspr != nil
        key = RenderStickerSheet.call(cspr)
        data = S3Download.call(key)
        filename = "PrintSheetRequest-#{params[:id]}-lifesquares.pdf"
        send_data data, :type=> 'application/pdf', :filename => filename
        return
      else
        render nothing: true, :status => 404
        return
      end
    end

    def update_status
      # meh, what could go wrong, ALL THE THINGS! but it's ok, it's just a status column in the admin
      # and it's protected by the employee requirement, so there
      cspr = CodeSheetPrintRequest.where(:code_sheet_print_request_id => params[:id]).first
      if cspr != nil
        status = params[:status].to_i
        cspr.status = status
        if status == 4
          cspr.mailed_at = Time.now
        else
          # MEH MEH MEH cry my a river
          cspr.mailed_at = nil
        end
        cspr.save
        render :json => {}, :status => 200
        return
      end
      render :json => {}, :status => 404
    end

  end
end