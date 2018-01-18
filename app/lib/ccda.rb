require 'nokogiri'
require 'date'

# validate that it is a Ambulatory Summary
#<code code="34133-9" codeSystem="2.16.840.1.113883.6.1" displayName="Summarization of Episode Note"/>
# PERMISSIONS? U/V = highly restricted
#   <confidentialityCode code="N" codeSystem="2.16.840.1.113883.5.25"/>
# PATIENT
#  recordTarget/patientRole
#  athenahealth patient id
#  <id root="2.16.840.1.113883.3.564.1959002" extension="3468"/>
#  athenahealth SSN
#  <id root="2.16.840.1.113883.4.1" extension="454545454"/>
# do we want to import home address or assume what we have is correct?
  #     <addr use="HP">
  #       <streetAddressLine>1 Dinklage Drive</streetAddressLine>
  #       <streetAddressLine nullFlavor="NI"/>
  #       <city>New York</city>
  #       <state>NY</state>
  #       <postalCode>10001</postalCode>
  #       <country>US</country>
  #     </addr>
  #     <telecom use="HP" value="tel:+1-212-6430001"/>
  #     <patient>
  #       <name>
  #         <given>Tyrion</given>
  #         <family>Lannister</family>
  #       </name>
  #       <administrativeGenderCode code="M" codeSystem="2.16.840.1.113883.5.1"/>
  #       <birthTime value="19690611"/>
  #       <maritalStatusCode code="M" codeSystem="2.16.840.1.113883.5.2" displayName="Married"/>
  #       <raceCode nullFlavor="NI"/>
  #       <ethnicGroupCode nullFlavor="NI"/>
  #       <languageCommunication>
  #         <languageCode nullFlavor="NA"/>
  #       </languageCommunication>
  #     </patient>
  #   </patientRole>
  # </recordTarget>



module Ccda

  LOINC_OID = '2.16.840.1.113883.6.1'
  LOINC_SUMMARY_OF_EPISODE_NOTE = '34133-9'
  LOINC_ALLERGIES_CODE = '48765-2'
  CCD_TEMPLATE_OID = '2.16.840.1.113883.10.20.22.1.1'
  CCD_HEADER_TEMPLATE_OID = '2.16.840.1.113883.10.20.22.1.2'
  ALLERGIES_TEMPLATE_OID = '2.16.840.1.113883.10.20.22.2.6.1'
#  ALLERGY_OBSERVATION_OID = '2.16.840.1.113883.10.20.22.4.7'
#  ALLERGY_PROBLEM_ACT_OID = '2.16.840.1.113883.10.20.22.4.30'
  MEDICATIONS_SECTION_OID = '2.16.840.1.113883.10.20.22.2.1.1'
  PROBLEMS_SECTION_OID = '2.16.840.1.113883.10.20.22.2.5.1'
  PROCEDURES_SECTION_OID = '2.16.840.1.113883.10.20.22.2.7.1'
  IMMUNIZATIONS_SECTION_OID = '2.16.840.1.113883.10.20.22.2.2.1'

  def self.import_emr_data(current_account, patient, ccda_xml)
    ccda_doc = Nokogiri::XML(ccda_xml)
    validate_ccda ccda_doc
    merge_allergies(current_account, patient, ccda_doc)
    merge_medications(current_account, patient, ccda_doc)
    merge_conditions(current_account, patient, ccda_doc)
    merge_procedures(current_account, patient, ccda_doc)
    merge_immunizations(current_account, patient, ccda_doc)
    patient.save
  end

  def self.validate_ccda(ccda_doc)
    type_id = ccda_doc.at_xpath("//xmlns:typeId")
    raise 'Invalid CDA document' unless '2.16.840.1.113883.1.3'.eql?(type_id.attribute('root').value)
    raise 'Invalid CDA document' unless 'POCD_HD000040'.eql?(type_id.attribute('extension').value)
    ccda_template = ccda_doc.at_xpath("//xmlns:templateId[@root='#{CCD_TEMPLATE_OID}']")
    raise 'Invalid Continuity of Care Document' unless ccda_template
    ccda_header_template = ccda_doc.at_xpath("//xmlns:templateId[@root='#{CCD_HEADER_TEMPLATE_OID}']")
    raise 'Invalid Continuity of Care Document' unless ccda_header_template
    ccda_code = ccda_doc.at_xpath("//xmlns:code[@codeSystem='#{LOINC_OID}' and @code='#{LOINC_SUMMARY_OF_EPISODE_NOTE}']")
    raise 'Invalid Continuity of Care Document' unless ccda_code
    true
  end

  def self.merge_allergies(current_account, patient, ccda_doc)
    allergies_template = ccda_doc.at_xpath("//xmlns:templateId[@root='#{ALLERGIES_TEMPLATE_OID}']")
    if allergies_template
      allergies_section = allergies_template.parent
      header_row = allergies_section.xpath("xmlns:text/xmlns:table/xmlns:thead/xmlns:tr")
      columns = Array.new
      header_row.xpath("xmlns:th").each do |column|
        columns << column.content
      end
      rows = allergies_section.xpath("xmlns:text/xmlns:table/xmlns:tbody/xmlns:tr")
      rows.each do |row|
        allergy = Hash.new
        i = 0
        row.xpath("xmlns:td").each do |td|
          allergy[columns[i]] = td.content
          i += 1
        end
        merge_allergy(current_account, patient, allergy)
      end
    end
  end

  def self.merge_allergy(current_account, patient, allergy)
    if !allergy_exists?(patient, allergy['Name'], allergy['Reaction'])
      imo_data = Imo.best_match(:allergy, allergy['Name'])
      imo_code = imo_data[:imo][:code] if imo_data
      icd9_code = imo_data[:icd9][:code] if imo_data
      icd10_code = imo_data[:icd10][:code] if imo_data
      patient_allergy = patient.patient_allergies.create
      patient_allergy.create_user = current_account.account_id
      patient_allergy.create_date = Time.now
      patient_allergy.update_user = current_account.account_id
      patient_allergy.last_update = Time.now
      patient_allergy.assign_attributes(
        allergen: allergy['Name'],
        reaction: allergy['Reaction'],
        start_date: allergy['Onset'],
        privacy: 'provider',
        imo_code: imo_code, icd9_code: icd9_code, icd10_code: icd10_code)
    end
  end

  def self.allergy_exists?(patient, allergen, reaction)
    patient.patient_allergies.select { |allergy| allergy.allergen.eql?(allergen) and allergy.reaction.eql?(reaction) }.any?
  end

  def self.merge_medications(current_account, patient, ccda_doc)
    medications_template = ccda_doc.at_xpath("//xmlns:templateId[@root='#{MEDICATIONS_SECTION_OID}']")
    if medications_template
      medications_section = medications_template.parent
      entries = medications_section.xpath("xmlns:entry")
      entries.each do |entry|
        medication = Hash.new
        medication['Frequency'] = entry.at_xpath("xmlns:substanceAdministration/xmlns:text").content

        quantity_element = entry.at_xpath("xmlns:substanceAdministration/xmlns:doseQuantity")
        quantity_value_attribute = quantity_element.attribute('value') if quantity_element
        medication['Quantity'] = quantity_value_attribute.value if quantity_value_attribute

        effective_time_low_element = entry.at_xpath("xmlns:substanceAdministration/xmlns:effectiveTime/xmlns:low")
        effective_time_low_value_attribute = effective_time_low_element.attribute('value') if effective_time_low_element
        effective_time = effective_time_low_value_attribute.value if effective_time_low_value_attribute
        medication['Date'] = effective_time[4..5] + '/' + effective_time[6..7] + '/' + effective_time[0..3] if effective_time

        name_element = entry.at_xpath("xmlns:substanceAdministration/xmlns:consumable/xmlns:manufacturedProduct/xmlns:manufacturedMaterial/xmlns:name")
        medication['Name'] = name_element.content

        code_element = entry.at_xpath("xmlns:substanceAdministration/xmlns:consumable/xmlns:manufacturedProduct/xmlns:manufacturedMaterial/xmlns:code")
        code_system_attribute = code_element.attribute("codeSystemName")
        code_attribute = code_element.attribute("code")
        medication['CodeSystem'] = code_system_attribute.value if code_system_attribute
        medication['Code'] = code_attribute.value if code_attribute
        merge_medication(current_account, patient, medication)
      end
    end
  end

  def self.merge_medication(current_account, patient, medication)
    if !therapy_exists?(patient, medication['Name'], medication['Date'])
      imo_data = Imo.best_match(:medication, medication['Name'])
      imo_code = imo_data[:imo][:code] if imo_data
      icd9_code = imo_data[:icd9][:code] if imo_data
      icd10_code = imo_data[:icd10][:code] if imo_data
      # TODO: add rxnorm column
      patient_therapy = patient.patient_therapies.create
      patient_therapy.create_user = current_account.account_id
      patient_therapy.create_date = Time.now
      patient_therapy.update_user = current_account.account_id
      patient_therapy.last_update = Time.now
      patient_therapy.assign_attributes(
        therapy: medication['Name'],
        therapy_frequency: medication['Frequency'],
        therapy_quantity: medication['Quantity'],
        start_date: medication['Date'],
        privacy: 'provider',
        imo_code: imo_code, icd9_code: icd9_code, icd10_code: icd10_code)
    end
  end

  def self.therapy_exists?(patient, therapy, start_date)
    patient.patient_therapies.select { |patient_therapy|
      patient_therapy.therapy.eql?(therapy) and
      patient_therapy.start_date.strftime('%m/%d/%Y').eql?(start_date)  }.any?
  end

  def self.merge_conditions(current_account, patient, ccda_doc)
    problems_template = ccda_doc.at_xpath("//xmlns:templateId[@root='#{PROBLEMS_SECTION_OID}']")
    if problems_template
      problems_section = problems_template.parent
      header_row = problems_section.xpath("xmlns:text/xmlns:table/xmlns:thead/xmlns:tr")
      columns = Array.new
      header_row.xpath("xmlns:th").each do |column|
        columns << column.content
      end
      rows = problems_section.xpath("xmlns:text/xmlns:table/xmlns:tbody/xmlns:tr")
      rows.each do |row|
        condition = Hash.new
        i = 0
        row.xpath("xmlns:td").each do |td|
          condition[columns[i]] = td.content
          i += 1
        end
        merge_condition(current_account, patient, condition)
      end
    end
  end

  def self.merge_condition(current_account, patient, condition)
    if !health_event_exists?(patient, 'CONDITION', condition['Name'], condition['Onset Date'])
      imo_data = Imo.best_match(:condition, condition['Name'])
      imo_code = imo_data[:imo][:code] if imo_data
      icd9_code = imo_data[:icd9][:code] if imo_data
      icd10_code = imo_data[:icd10][:code] if imo_data
      patient_health_event = patient.patient_health_events.create
      patient_health_event.create_user = current_account.account_id
      patient_health_event.create_date = Time.now
      patient_health_event.update_user = current_account.account_id
      patient_health_event.last_update = Time.now
      patient_health_event.assign_attributes(
        health_event: condition['Name'],
        health_event_type: 'CONDITION',
        start_date: condition['Onset Date'],
        privacy: 'provider',
        start_date_mask: 'MM/DD/YY',
        imo_code: imo_code, icd9_code: icd9_code, icd10_code: icd10_code)
    end
  end

  def self.merge_procedures(current_account, patient, ccda_doc)
    procedures_template = ccda_doc.at_xpath("//xmlns:templateId[@root='#{PROCEDURES_SECTION_OID}']")
    if procedures_template
      procedures_section = procedures_template.parent
      header_row = procedures_section.xpath("xmlns:text/xmlns:table/xmlns:thead/xmlns:tr")
      columns = Array.new
      header_row.xpath("xmlns:th").each do |column|
        columns << column.content
      end
      rows = procedures_section.xpath("xmlns:text/xmlns:table/xmlns:tbody/xmlns:tr")
      rows.each do |row|
        procedure = Hash.new
        i = 0
        row.xpath("xmlns:td").each do |td|
          procedure[columns[i]] = td.content
          i += 1
        end
        merge_procedure(current_account, patient, procedure)
      end
    end
  end

  def self.merge_procedure(current_account, patient, procedure)
    if !health_event_exists?(patient, 'PROCEDURE', procedure['Name'], procedure['Date'])
      imo_data = Imo.best_match(:procedure, procedure['Name'])
      imo_code = imo_data[:imo][:code] if imo_data
      icd9_code = imo_data[:icd9][:code] if imo_data
      icd10_code = imo_data[:icd10][:code] if imo_data
      patient_health_event = patient.patient_health_events.create
      patient_health_event.create_user = current_account.account_id
      patient_health_event.create_date = Time.now
      patient_health_event.update_user = current_account.account_id
      patient_health_event.last_update = Time.now
      patient_health_event.assign_attributes(
        health_event: procedure['Name'],
        health_event_type: 'PROCEDURE',
        start_date: procedure['Date'],
        privacy: 'provider',
        start_date_mask: 'MM/DD/YY',
        imo_code: imo_code, icd9_code: icd9_code, icd10_code: icd10_code)
    end
  end

  def self.merge_immunizations(current_account, patient, ccda_doc)
    immunizations_template = ccda_doc.at_xpath("//xmlns:templateId[@root='#{IMMUNIZATIONS_SECTION_OID}']")
    if immunizations_template
      immunizations_section = immunizations_template.parent
      entries = immunizations_section.xpath("xmlns:entry")
      entries.each do |entry|
        immunization = Hash.new
        effective_time = entry.at_xpath("xmlns:substanceAdministration/xmlns:effectiveTime").attribute('value').value
        immunization['Date'] = effective_time[4..5] + '/' + effective_time[6..7] + '/' + effective_time[0..3]
        immunization['Name'] = entry.at_xpath("xmlns:substanceAdministration/xmlns:consumable/xmlns:manufacturedProduct/xmlns:manufacturedMaterial/xmlns:code/xmlns:originalText").content
        merge_immunization(current_account, patient, immunization)
      end
    end
  end

  def self.merge_immunization(current_account, patient, immunization)
    if !health_event_exists?(patient, 'IMMUNIZATION', immunization['Name'], immunization['Date'])
      imo_data = Imo.best_match(:immunization, immunization['Name'])
      imo_code = imo_data[:imo][:code] if imo_data
      icd9_code = imo_data[:icd9][:code] if imo_data
      icd10_code = imo_data[:icd10][:code] if imo_data
      patient_health_event = patient.patient_health_events.create
      patient_health_event.create_user = current_account.account_id
      patient_health_event.create_date = Time.now
      patient_health_event.update_user = current_account.account_id
      patient_health_event.last_update = Time.now
      patient_health_event.assign_attributes(
        health_event: immunization['Name'],
        health_event_type: 'IMMUNIZATION',
        start_date: immunization['Date'],
        privacy: 'provider',
        start_date_mask: 'MM/DD/YY',
        imo_code: imo_code, icd9_code: icd9_code, icd10_code: icd10_code)
    end
  end

  # TODO: add start date logic
  def self.health_event_exists?(patient, health_event_type, health_event, start_date)
    patient.patient_health_events.select { |patient_health_event|
      patient_health_event.health_event_type.eql?(health_event_type) and
      patient_health_event.health_event.eql?(health_event) and
      patient_health_event.start_date.strftime('%m/%d/%Y').eql?(start_date) }.any?
  end


end
