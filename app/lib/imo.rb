require 'date'
require 'socket'
require 'rexml/document'
include REXML
require 'json'

module Imo

  class ImoData

  end

HOSTNAME = "portal.e-imo.com"
IMO_TIMEOUT = 7
MAX_RESULTS_REQUESTED = 50
##at should use these (dym) if no items (results)
MAX_NUMBER_OF_DID_YOU_MEAN_RESULTS = 10

JSON_FORMAT_TYPE = 2
XML_FORMAT_TYPE  = 1

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

  # find the best match for a category and term
  # valid categories: medication, condition, allergy, procedure, device, immunization
  # returns a hash similar to:
  #
  # { :category=>"medication", :title=>"Aspirin", :code=>125475,
  # :imo=>{:code=>"125475", :title=>"Aspirin"},
  # :kndg=>{:source=>"MedicationIT", :code=>"125475"},
  # :icd9=>{:code=>nil, :title=>nil},
  # :icd10=>{:code=>nil, :title=>nil},
  # :rxnorm=>{:code=>"1191"},
  # :snomed=>{:code=>nil, :title=>nil} }
  #
  # to access icd10 code:
  #
  # imo_best_match = Imo.best_match(:medication, "Aspirin")
  # icd10_code = imo_best_match[:icd10][:code] if imo_best_match
  #
  def self.best_match(category, term)
    best_match = nil
    results = self.search(category, term)
    if results
      options = results[:combinations]
      # see if there is an exact match
      best_match = options.select { |x| x[:title] and term.downcase.eql?(x[:title].downcase) }.first
      # just chose the first if no exact match
      # TODO: try to be a bit smarter
      best_match ||= options.first
    end
    best_match 
  end


  def self.json_best_match(category, term)
    best_match = nil
    results = self.json_search(category, term)
    if results
      options = results[:combinations]
      # see if there is an exact match
      best_match = options.select { |x| x[:title] and term.downcase.eql?(x[:title].downcase) }.first
      # just chose the first if no exact match
      # TODO: try to be a bit smarter
      best_match ||= options.first
    end
    best_match 
  end

  def self.json_search(category, term)
    return nil if category.nil? and term.nil?

    imo_access_id = Rails.application.config.imo[:access_id]
    imo_category =  IMO_CATEGORIES[ category.to_sym ]

    results = nil
    if imo_category
      port = imo_category[:port]
      prefix = imo_category[:prefix]
      query = "search^#{MAX_RESULTS_REQUESTED}|#{MAX_NUMBER_OF_DID_YOU_MEAN_RESULTS}|#{JSON_FORMAT_TYPE}^#{prefix}#{term}#{imo_category[:filter]}^#{imo_access_id}"
      imo_response = request_imo_data port ,  query
      if imo_response.length
        data = (JSON.parse imo_response)["data"]
        if data
          combinations = []
          items = []
          codes = Hash.new
          data["items"].each do |item|
            kndg_source = item["kndg_source"]
            kndg_code = item["kndg_code"]
            title = item["title"]
            code = item['code'].to_i
            imo = { :code => item['code'], :title => item["title"] } if item['code']
            icd9 = { :code => item['ICD10CM_CODE'], :title => item['ICD10CM_TITLE'] }
            icd9 = { :code => item["kndg_code"], :title => item["kndg_title"] } if 'ICD9'.eql?(kndg_source)
            icd10 = { :code => item['ICD10CM_CODE'], :title => item['ICD10CM_TITLE'] }
            rxnorm = { :code => item['RXCUI'] }
            combined = {:category => category.to_s, :title => title, :code => code, :imo => imo, :kndg => {:source => kndg_source, :code => kndg_code}}
            combined[:icd9] = icd9
            combined[:icd10] = icd10
            combined[:rxnorm] = rxnorm
            codes[title] = code
            combinations << combined
            items << title
          end
          items.sort!  { |a,b| a.length <=>  b.length }
          results = { :items => items , :codes => codes , :combinations => combinations}
        end
      end
    end
    results
  end

  def self.search(category, term)
    return nil if category.nil? and term.nil?

    imo_access_id = Rails.application.config.imo[:access_id]
    imo_category =  IMO_CATEGORIES[ category.to_sym ]

    results = nil
    if imo_category
      port = imo_category[:port]
      prefix = imo_category[:prefix]
      query = "search^#{MAX_RESULTS_REQUESTED}|#{MAX_NUMBER_OF_DID_YOU_MEAN_RESULTS}|#{XML_FORMAT_TYPE}^#{prefix}#{term}#{imo_category[:filter]}^#{imo_access_id}"
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
                imo = { :code => item.attributes['code'], :title => item.attributes["title"] } if item.attributes['code']
                icd9 = { :code => item.attributes['ICD10CM_CODE'], :title => item.attributes['ICD10CM_TITLE'] }
                icd9 = { :code => item.attributes["kndg_code"], :title => item.attributes["kndg_title"] } if 'ICD9'.eql?(kndg_source)
                icd10 = { :code => item.attributes['ICD10CM_CODE'], :title => item.attributes['ICD10CM_TITLE'] }
                rxnorm = { :code => item.attributes['RXCUI'] }
                snomed = { :code => item.attributes['SCT_CONCEPT_ID'], :title => item.attributes['SNOMED_DESCRIPTION'] }
                combined = {:category => category.to_s, :title => title, :code => code, :imo => imo, :kndg => {:source => kndg_source, :code => kndg_code}}
                combined[:icd9] = icd9
                combined[:icd10] = icd10
                combined[:rxnorm] = rxnorm
                combined[:snomed] = snomed
                codes[title] = code
                combinations << combined
                items << title
              end
           items.sort!  { |a,b| a.length <=>  b.length }
           #combinations.sort!  { |a,b| a[0].length <=>  b[0].length }
           results = { :items => items , :codes => codes , :combinations => combinations}
        end
      end
    end
    results
  end

  def self.medication_detail(med_name)
    return nil if med_name.nil?
    strength_form_recs = ImoMedNameStrengthForm.where(med_name: med_name)
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
  def self.request_imo_data( port , query_request )
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
