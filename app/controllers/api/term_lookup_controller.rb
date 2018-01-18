require 'socket'
require 'rexml/document'
include REXML
require 'yaml'

module Api
  class TermLookupController < Api::ApplicationController
    before_action :authenticate_account

    HOSTNAME = "portal.e-imo.com"
    IMO_TIMEOUT = 7
    MAX_RESULTS_REQUESTED = 50
    ##at should use these (dym) if no items (results)
    MAX_NUMBER_OF_DID_YOU_MEAN_RESULTS = 10

    JSON_FORMAT_TYPE = 2
    XML_FORMAT_TYPE  = 1

    CREDS = YAML::load_file(Rails.root.join('config/credentials-local.yml'))

    IMO_CONSUMER_PORT     = 42013            # 42011: Professional, 42013: Consumer
    IMO_PROFESSIONAL_PORT = 42011
    IMO_MEDICATION_PORT   = 42019

    IMO_CATEGORIES =   {
        :medication   => { :port => IMO_MEDICATION_PORT, :prefix => "", :filter => %{|NVL(ACTIVE_FLAG,3) <> 0}  } ,
        :condition    => { :port => IMO_PROFESSIONAL_PORT, :prefix => ""  } ,
        :allergy      => { :port => IMO_PROFESSIONAL_PORT, :prefix => ""  } ,
        :procedure    => { :port => IMO_PROFESSIONAL_PORT, :prefix => ""  } ,
        :device       => { :port => IMO_PROFESSIONAL_PORT, :prefix => ""  } ,
        :immunization => { :port => IMO_PROFESSIONAL_PORT, :prefix => "", :filter => %{|(INDEXOF(SUBDOMAINS,4)>0)}  } ,
    }

  
    def search
      if false==params.has_key?(:category) || false==params.has_key?(:term)
        return render(:text => 'Unauthorized access', :layout => false, :status => 403)
      end

      category =  IMO_CATEGORIES[ params[:category].to_sym ]

      reply = ""
      if category
        port = category[:port]
        prefix = category[:prefix]
        query = "search^#{MAX_RESULTS_REQUESTED}|#{MAX_NUMBER_OF_DID_YOU_MEAN_RESULTS}|#{XML_FORMAT_TYPE}^#{prefix}#{params[:term]}#{category[:filter]}^#{CREDS['imo']['access_id']}"
        imo_response = request_imo_data port ,  query

        if imo_response.length > 0

            xml_doc = REXML::Document.new(imo_response)
            if xml_doc
                combinations = []
                items = []
                codes = Hash.new
                xml_doc.elements.each('items/item') do |item|
                  kndg_source = item.attributes["kndg_source"]
                  kndg_code = item.attributes["kndg_code"]
                  title = item.attributes["title"]
                  code = item.attributes['code'].to_i
                  combined = {:title => title, :code => code, :kndg => {:source => kndg_source, :code => kndg_code}}
                  codes[title] = code
                  combinations << combined
                  items << title
                end
             items.sort!  { |a,b| a.length <=>  b.length }
             #combinations.sort!  { |a,b| a[0].length <=>  b[0].length }
             final = { :items => items , :codes => codes , :combinations => combinations}
             reply = final.to_json

          end
        end
      else
        return render(:text => 'Unauthorized access', :layout => false, :status => 403)
      end

      render(:text => reply, :layout => false, :content_type => 'application/json', :content_length => reply.length )
    end

    def medication_detail
      if false==params.has_key?(:med_name)
        return render(:text => 'Unauthorized access', :layout => false, :status => 403)
      end

      strength_form_recs = ImoMedNameStrengthForm.where(med_name: params[:med_name])
      strength_forms = []
      strength_form_recs.try(:each) {|r| strength_forms << r.strength_form }

      final = { :routes => strength_forms  }

      render(:text => final.to_json, :layout => false, :content_type => 'application/json')
    end

  private

    ########################################################################
    #
    # @param port [integer]
    # @param query_request [string]
    #
    # @return imo_response [string]
    #
    ########################################################################
    def request_imo_data( port , query_request )
       s = TCPSocket.open( HOSTNAME, port )
       s.puts(query_request)
       imo_response = ""
       result = select( [s], nil, nil, IMO_TIMEOUT )
       if result
         ## First bytes as the size to expect
         size_str = s.recv(4)
         size = (size_str[0].ord << 24) +(size_str[1].ord << 16) +(size_str[2].ord << 8) +(size_str[3].ord )
         imo_response = ""
         while imo_response.length < size
           imo_response += s.recv(size)
         end
       end
       s.close
       imo_response
    end
  end
end
