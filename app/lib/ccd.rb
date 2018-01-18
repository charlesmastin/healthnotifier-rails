require 'nokogiri'
require 'date'

module Ccd

  def to_ccd_xml(patient)
#    builder = Nokogiri::XML::Builder.new { |xml|
#      xml.ClinicalDocument(
#        'xmlns' => 'urn:hl7-org:v3',
#        'xmlns:voc' => 'urn:hl7-org:v3/voc',
#        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
#        'xsi:schemaLocation' => 'urn:hl7-org:v3 CDA.xsd') do
#        to_ccd_header(xml, patient)
#      end
#    }
    builder = Nokogiri::XML::Builder.new { |xml|
      xml.ClinicalDocument(
        'classCode' => 'DOCCLIN',
        'moodCode' => 'EVN',
        'xmlns' => 'urn:hl7-org:v3',
        'xmlns:sdtc' => 'urn:hl7-org:sdtc',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'urn:hl7-org:v3 http://xreg2.nist.gov:8080/hitspValidation/schema/cdar2c32/infrastructure/cda/C32_CDA.xsd') do
        to_ccd_header(xml, patient)
        to_ccd_body(xml, patient)
      end
    }
    doc = Nokogiri::XML builder.to_xml
    # horrible hack required to add xml-stylesheet processing instruction
#    doc.root.add_previous_sibling Nokogiri::XML::ProcessingInstruction.new(doc, "xml-stylesheet", 'type="text/xsl" href="CDASchemas\cda\Schemas\CCD.xsl"')
#    doc.to_xml
  end
  module_function :to_ccd_xml

  def self.to_ccd_header(xml, patient)
    xml.realmCode('code' => 'US')
    xml.typeId('extension' => 'POCD_HD000040', 'root' => '2.16.840.1.113883.1.3')
    xml.templateId('assigningAuthorityName' => 'CDA/R2', 'root' => '2.16.840.1.113883.3.27.1776')
    xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1')
    xml.templateId('assigningAuthorityName' => 'CDA4CDT', 'root' => '2.16.840.1.113883.10.20.3')
    xml.templateId('assigningAuthorityName' => 'HITSP/C32', 'root' => '2.16.840.1.113883.3.88.11.32.1')
    xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.1.1')
    # TODO: use UUID instead of database id. change root after HL7 OID
    xml.id_('extension' => patient.id.to_s, 'root' => '2.16.840.1.113883.3.564.1959002')
    xml.code('code' => '34133-9', 'codeSystem' => '2.16.840.1.113883.6.1', 'codeSystemName' => 'LOINC', 'displayName' => 'Summarization of episode note')
    # TODO: after HL7 issues OID: xml.title 'Lifesquare Continuity of Care Document'
    xml.title('CCD Export Record')
    xml.effectiveTime('value' => Time.now.utc.strftime("%Y%m%d%H%M%S%z"))
    xml.confidentialityCode('code' => 'N', 'codeSystem' => '2.16.840.1.113883.5.25')
    xml.languageCode('code' => 'en-US')
    xml.recordTarget('contextControlCode' => 'OP', 'typeCode' => 'RCT') do
      xml.patientRole('classCode' => 'PAT') do
        xml.id_('extension' => patient.id.to_s, 'root' => '2.16.840.1.113883.3.564.1959002')
        xml.addr('nullFlavor' => 'NI')
        xml.telecom('nullFlavor' => 'NI', 'use' => 'HP')
        xml.telecom('nullFlavor' => 'NI', 'use' => 'WP')
        xml.patient('classCode' => 'PSN', 'determinerCode' => 'INSTANCE') do
          xml.name do
            xml.given patient.first_name
            xml.family patient.last_name
          end
          xml.administrativeGenderCode('code' => patient.gender, 'codeSystem' => '2.16.840.1.113883.5.1', 'codeSystemName' => 'HL7 AdministrativeGenderCodes', 'displayName' => patient.gender)
          xml.birthTime('value' => patient.birthdate.strftime('%Y%m%d%H%M%S')) if patient.birthdate
          # TODO: add marital status to database
          xml.maritalStatusCode('code' => 'M', 'codeSystem' => '2.16.840.1.113883.5.2', 'codeSystemName' => 'HL7 MaritalStatus', 'displayName' => 'Married')
          patient.patient_languages.each_with_index do |patient_language, i|
            xml.languageCommunication do
              xml.templateId('assigningAuthorityName' => 'HITSP/C83', 'root' => '2.16.840.1.113883.3.88.11.83.2')
              xml.templateId('assigningAuthorityName' => 'HITSP/C32', 'root' => '2.16.840.1.113883.3.88.11.32.2')
              xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.2.1')
              xml.languageCode('code' => patient_language.language_code)
              # TODO: use language_proficiency instead of order to determine preference? or just add it to the database?
              xml.preferenceInd('value' => i.eql?(0).to_s)
            end
          end
        end
      end
    end
    xml.author('contextControlCode' => 'OP', 'typeCode' => 'AUT') do
      xml.time('value' => Time.now.utc.strftime("%Y%m%d%H%M%S"))
      xml.assignedAuthor('classCode' => 'ASSIGNED') do
        xml.id_
        xml.addr do
          xml.city('Mill Valley')
          xml.country('US')
          xml.postalCode('94941')
          xml.state('CA')
          xml.streetAddressLine
        end
        xml.telecom('nullFlavor' => 'NI')
        xml.assignedPerson('classCode' => 'PSN', 'determinerCode' => 'INSTANCE') do
          xml.name('nullFlavor' => 'UNK')
        end
        xml.representedOrganization('classCode' => 'ORG', 'determinerCode' => 'INSTANCE') do
          xml.id_
          xml.name('LifeQode, Inc')
          xml.telecom('nullFlavor' => 'NI')
          xml.addr do
            xml.city('Mill Valley')
            xml.country('US')
            xml.postalCode('94941')
            xml.state('CA')
            xml.streetAddressLine
          end
        end
      end
    end
    xml.informant('contextControlCode' => 'OP', 'typeCode' => 'INF') do
      xml.assignedEntity('classCode' => 'ASSIGNED') do
        xml.id_
        xml.addr do
          xml.city('Mill Valley')
          xml.country('US')
          xml.postalCode('94941')
          xml.state('CA')
          xml.streetAddressLine
        end
        xml.telecom('nullFlavor' => 'NI')
        xml.assignedPerson('classCode' => 'PSN', 'determinerCode' => 'INSTANCE') do
          xml.name('nullFlavor' => 'UNK')
        end
        xml.representedOrganization('classCode' => 'ORG', 'determinerCode' => 'INSTANCE') do
          xml.id_
          xml.name('LifeQode, Inc')
          xml.telecom('nullFlavor' => 'NI')
          xml.addr do
            xml.city('Mill Valley')
            xml.country('US')
            xml.postalCode('94941')
            xml.state('CA')
            xml.streetAddressLine
          end
        end
      end
    end
    xml.custodian('typeCode' => 'CST') do
      xml.assignedCustodian('classCode' => 'ASSIGNED') do
        xml.representedCustodianOrganization('classCode' => 'ORG', 'determinerCode' => 'INSTANCE') do
          xml.id_
          xml.name('lifeqode')
          xml.telecom('nullFlavor' => 'NI')
          xml.addr('nullFlavor' => 'NI')
        end
      end
    end
#  <participant contextControlCode="OP" typeCode="IND">
#    <templateId assigningAuthorityName="HITSP/C83" root="2.16.840.1.113883.3.88.11.83.3" />
#    <templateId assigningAuthorityName="IHE" root="1.3.6.1.4.1.19376.1.5.3.1.2.4" />
#    <templateId assigningAuthorityName="HITSP/C32" root="2.16.840.1.113883.3.88.11.32.3" />
#    <time value="20150717000000" />
#    <associatedEntity classCode="ECON">
#      <id />
#      <code code="FRIEND" codeSystem="2.16.840.1.113883.5.111" displayName="FRIEND" />
#      <addr nullFlavor="NI" />
#      <telecom value="tel:6502701966" />
#      <associatedPerson classCode="PSN" determinerCode="INSTANCE">
#        <name><given>Kristin</given><family>Duriseti</family></name>
#      </associatedPerson>
#    </associatedEntity>
#  </participant>
    xml.documentationOf('typeCode' => 'DOC') do
      xml.serviceEvent('classCode' => 'PCPR', 'moodCode' => 'EVN') do
        xml.effectiveTime do
          xml.low('nullFlavor' => 'UNK')
          xml.high('nullFlavor' => 'UNK')
        end
      end
    end
  end

  def self.to_ccd_body(xml, patient)
    xml.component('contextConductionInd' => 'true', 'typeCode' => 'COMP') do
      xml.structuredBody('classCode' => 'DOCBODY', 'moodCode' => 'EVN') do
        to_ccd_conditions(xml, patient)
        to_ccd_medications(xml, patient)
        to_ccd_allergies(xml, patient)
        to_ccd_diagnostic_results(xml, patient)
        to_ccd_immunizations(xml, patient)
        to_ccd_procedures(xml, patient)
      end
    end
  end

  def self.to_ccd_conditions(xml, patient)
    xml.component('contextConductionInd' => 'true', 'typeCode' => 'COMP') do
      xml.section('classCode' => 'DOCSECT', 'moodCode' => 'EVN') do
        xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.11')
        xml.templateId('assigningAuthorityName' => 'HITSP/C32', 'root' => '2.16.840.1.113883.3.88.11.32.7')
        xml.templateId('assigningAuthorityName' => 'HITSP/C83', 'root' => '2.16.840.1.113883.3.88.11.83.103')
        xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.3.6')
        xml.code('code' => '11450-4', 'codeSystem' => '2.16.840.1.113883.6.1', 'codeSystemName' => 'LOINC', 'displayName' => 'Problem list')
        xml.title('Conditions or Problems')
        conditions = patient.patient_health_events.select { |event| event.health_event_type.eql?('CONDITION') }
        # currently sorting conditions based on create_date
        # TODO: populate start_date for conditions?
        sorted_conditions = conditions.sort_by {|event| event.create_date}
        snomed_codes = {}
        xml.text_ do
          xml.table('border' => '1', 'width' => '100%') do
            xml.thead do
              xml.tr do
                xml.th('Problem Name')
                xml.th('SNOMED Code')
                xml.th('Onset Date')
              end
            end
            xml.tbody do
              sorted_conditions.each do |condition|
                xml.tr do
                  xml.td('rowspan' => '1') do
                    xml.content(condition.health_event, 'ID' => "problem-#{condition.id}")
                  end
                  xml.td('rowspan' => '1') do
                    # TODO: populate the database with IMO/RxNorm/SNOMED
                    imo_result = Imo.best_match(:condition, condition.health_event)
                    if imo_result and imo_result[:snomed] and imo_result[:snomed][:code]
                      xml.content(imo_result[:snomed][:code])
                      snomed_codes[condition.id] = imo_result[:snomed][:code]
                    else
                      xml.content('')
                    end
                  end
                  xml.td('rowspan' => '1') do
                    xml.content((condition.start_date || condition.create_date).strftime('%m/%d/%Y'))
                  end
                end
              end
            end
          end
        end
        sorted_conditions.each do |condition|
          xml.entry('contextConductionInd' => 'true', 'typeCode' => 'COMP') do
            xml.act('classCode' => 'ACT', 'typeCode' => 'EVN') do
              xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.27')
              xml.templateId('assigningAuthorityName' => 'HITSP/C83', 'root' => '2.16.840.1.113883.3.88.11.83.7')
              xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.4.5.1')
              xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.4.5.2')
              xml.id_
              xml.code('nullFlaver' => 'NA')
              xml.statusCode('code' => 'completed')
              xml.effectiveTime do
                xml.low('value' => (condition.start_date || condition.create_date).strftime('%Y%m%d%H%M%S'))
                xml.high(condition.end_date ? {'value' => condition.end_date.strftime('%Y%m%d%H%M%S')} : {'nullFlavor' => 'UNK'})
              end
              xml.entryRelationship('contextConductionInd' => 'true', 'inversionInd' => 'false', 'typeCode' => 'SUBJ') do
                xml.observation('classCode' => 'OBS', 'moodCode' => 'EVN') do
                  xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.28')
                  xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.4.5')
                  xml.id_('root' => "#{patient.id}.#{condition.id}")
                  xml.code('nullFlaver' => 'NA')
                  xml.text_ do
                    xml.reference('value' => "#problem-#{condition.id}")
                  end
                  xml.statusCode('code' => 'completed')
                  xml.effectiveTime do
                    xml.low('value' => (condition.start_date || condition.create_date).strftime('%Y%m%d%H%M%S'))
                    xml.high('value' => condition.end_date ? condition.end_date.strftime('%Y%m%d%H%M%S') : 'UNK')
                  end
                  xml.value_('displayName' => condition.health_event, 'xsi:type' => 'CD') do
                    xml.translation('code' => snomed_codes[condition.id], 'codeSystem' => '2.16.840.1.113883.6.96', 'codeSystemName' => 'SNOMED CT')
                  end

                  xml.informant('contextControlCode' => 'OP', 'typeCode' => 'INF') do
                    xml.assignedEntity('classCode' => 'ASSIGNED') do
                      xml.id_
                      xml.addr('nullFlavor' => 'NI')
                      xml.telecom('nullFlavor' => 'NI')
                      xml.assignedPerson('classCode' => 'PSN', 'determinerCode' => 'INSTANCE') do
                        xml.name('nullFlavor' => 'UNK')
                      end
                      xml.representedOrganization('classCode' => 'ORG', 'determinerCode' => 'INSTANCE') do
                        xml.name('LifeQode, Inc')
                        xml.telecom('nullFlavor' => 'NI')
                        xml.addr('nullFlavor' => 'NI')
                      end
                    end
                  end
                  #xml.entryRelationship('contextConductionInd' => 'true', 'inversionInd' => 'false', 'typeCode' => 'REFR') do
                  #  xml.observation('classCode' => 'OBS', 'moodCode' => 'EVN') do
                  #    xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.50')
                  #    xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.57')
                  #    xml.code_('code' => '33999-4', 'codeSystem' => '2.16.840.1.113883.6.1', 'codeSystemName' => 'LOINC', 'displayName' => 'Status')
                  #    xml.statusCode('code' => 'completed')
                  #    xml.value_('code' => '90734009', 'codeSystem' => '2.16.840.1.113883.6.96', 'codeSystemName' => 'SNOMED CT', 'displayName' => 'Chronic', 'xsi:type' => 'CD')
                  #  end 
                  #end
                end
              end
            end
          end
        end
      end
    end
  end

  def self.to_ccd_medications(xml, patient)
    xml.component('contextConductionInd' => 'true', 'typeCode' => 'COMP') do
      xml.section('classCode' => 'DOCSECT', 'moodCode' => 'EVN') do
        xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.8')
        xml.templateId('assigningAuthorityName' => 'HITSP/C32', 'root' => '2.16.840.1.113883.3.88.11.32.8')
        xml.templateId('assigningAuthorityName' => 'HITSP/C83', 'root' => '2.16.840.1.113883.3.88.11.83.112')
        xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.3.19')
        xml.code('code' => '10160-0', 'codeSystem' => '2.16.840.1.113883.6.1', 'codeSystemName' => 'LOINC', 'displayName' => 'History of medication use')
        xml.title('Medications')
        # currently sorting medications based on create_date
        # TODO: populate start_date for patient_therapy?
        sorted_medications = patient.patient_therapies.sort_by {|therapy| therapy.create_date}
        # TODO: add RxNorm column to the database and populate
        rxnorm_codes = {}
        xml.text_ do
          xml.table('border' => '1', 'width' => '100%') do
            xml.thead do
              xml.tr do
                xml.th('FDB Name')
                xml.th('Sig')
                xml.th('Start Date')
                xml.th('Stop Date')
                xml.th('RxNorm Name')
                xml.th('RxNorm Code')
                xml.th('Note')
              end
            end
            xml.tbody do
              sorted_medications.each do |medication|
                xml.tr do
                  xml.td('rowspan' => '1') do
                    xml.content("#{medication.therapy} #{medication.therapy_strength_form}", 'ID' => "medication-#{medication.id}")
                  end
                  xml.td('rowspan' => '1') do
                    xml.content("#{medication.therapy_quantity} #{medication.therapy_frequency}", 'ID' => "sig-#{medication.id}")
                  end
                  xml.td('rowspan' => '1') do
                    xml.content((medication.start_date || medication.create_date).strftime('%m/%d/%Y'))
                  end
                  xml.td('rowspan' => '1') do
                    xml.content(medication.end_date ? medication.end_date.strftime('%m/%d/%Y') : '')
                  end
                  # TODO: populate the database with RxNorm
                  imo_result = Imo.best_match(:medication, medication.therapy)
                  # TODO: RxNorm Name?
                  xml.td('rowspan' => '1') do
                    xml.content('')
                  end
                  xml.td('rowspan' => '1') do
                    if imo_result and imo_result[:rxnorm] and imo_result[:rxnorm][:code]
                      xml.content(imo_result[:rxnorm][:code])
                      rxnorm_codes[medication.id] = imo_result[:rxnorm][:code]
                    else
                      xml.content('')
                    end
                  end
                  # TODO: notes?
                  xml.td('rowspan' => '1') do
                    xml.content('')
                  end
                end
              end
            end
          end
        end
        sorted_medications.each do |medication|
          xml.entry('contextConductionInd' => 'true', 'typeCode' => 'COMP') do
            xml.substanceAdministration('classCode' => 'SBADM', 'typeCode' => 'EVN') do
              xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.24')
              xml.templateId('assigningAuthorityName' => 'HITSP/C83', 'root' => '2.16.840.1.113883.3.88.11.83.8')
              xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.4.7')
              xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.4.7.1')
              xml.id_
              xml.text_ do
                xml.reference('value' => "medication-#{medication.id}")
              end
              xml.statusCode('code' => 'completed')
              xml.effectiveTime('xsi:type' => 'IVL_TS') do
                xml.low('value' => (medication.start_date || medication.create_date).strftime('%Y%m%d%H%M%S'))
                xml.high('value' => medication.end_date ? medication.end_date.strftime('%Y%m%d%H%M%S') : 'UNK')
                xml.high(medication.end_date ? {'value' => medication.end_date.strftime('%Y%m%d%H%M%S')} : {'nullFlavor' => 'UNK'})
              end
              # TODO: should we store RouteOfAdministration in database?
              xml.routeCode('nullFlavor' => 'UNK')
              # TODO: do we need to handle medication relationships?

              # TODO: does this always apply?
              xml.consumable('typeCode' => 'CSM') do
                xml.manufacturedProduct('classCode' => 'MANU') do
                  xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.53')
                  xml.templateId('assigningAuthorityName' => 'HITSP/C83', 'root' => '2.16.840.1.113883.3.88.11.83.8.2')
                  xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.4.7.2')
                  xml.manufacturedMaterial('classCode' => 'MMAT', 'determinerCode' => 'KIND') do
                    xml.code(rxnorm_codes[medication.id] \
                      ? {'code' => rxnorm_codes[medication.id], 'codeSystem' => '2.16.840.1.113883.6.88', 'codeSystemName' => 'RxNorm', 'displayName' => medication.therapy} \
                      : {'nullFlavor' => 'UNK'}) do
                      xml.originalText do
                        xml.reference('value' => "medication-#{medication.id}")
                      end
                      xml.translation('code' => rxnorm_codes[medication.id], 'codeSystem' => '2.16.840.1.113883.6.88', 'codeSystemName' => 'RxNorm', 'displayName' => medication.therapy) if rxnorm_codes[medication.id]
                    end
                    xml.name(medication.therapy)
                  end
                end
              end
              xml.author('contextControlCode' => 'OP', 'typeCode' => 'AUT') do
                xml.time('value' => Time.now.utc.strftime("%Y%m%d%H%M%S"))
                xml.assignedAuthor('classCode' => 'ASSIGNED') do
                  xml.id_
                  xml.addr('nullFlavor' => 'NI')
                  xml.telecom('nullFlavor' => 'NI')
                  xml.assignedPerson('classCode' => 'PSN', 'determinerCode' => 'INSTANCE') do
                    xml.name('nullFlavor' => 'UNK')
                  end
                end
              end
              xml.informant('contextControlCode' => 'OP', 'typeCode' => 'INF') do
                xml.assignedEntity('classCode' => 'ASSIGNED') do
                  xml.id_
                  xml.addr('nullFlavor' => 'NI')
                  xml.telecom('nullFlavor' => 'NI')
                  xml.assignedPerson('classCode' => 'PSN', 'determinerCode' => 'INSTANCE') do
                    xml.name('nullFlavor' => 'UNK')
                  end
                  xml.representedOrganization('classCode' => 'ORG', 'determinerCode' => 'INSTANCE') do
                    xml.id_
                    xml.name('LifeQode, Inc')
                    xml.telecom('nullFlavor' => 'NI')
                    xml.addr('nullFlavor' => 'NI')
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def self.to_ccd_allergies(xml, patient)
    xml.component('contextConductionInd' => 'true', 'typeCode' => 'COMP') do
      xml.section('classCode' => 'DOCSECT', 'moodCode' => 'EVN') do
        xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.2')
        xml.templateId('assigningAuthorityName' => 'HITSP/C32', 'root' => '2.16.840.1.113883.3.88.11.32.6')
        xml.templateId('assigningAuthorityName' => 'HITSP/C83', 'root' => '2.16.840.1.113883.3.88.11.83.102')
        xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.3.13')
        xml.code('code' => '48765-2', 'codeSystem' => '2.16.840.1.113883.6.1', 'codeSystemName' => 'LOINC', 'displayName' => 'Alerts, adverse reactions, alerts')
        xml.title('Allergies and Alert Problems')
        # currently sorting medications based on create_date
        # TODO: populate start_date for patient_allergy?
        sorted_allergies = patient.patient_allergies.sort_by {|allergy| allergy.create_date}
        # TODO: add RxNorm column to the database and populate
        rxnorm_codes = {}
        xml.text_ do
          xml.table('border' => '1', 'width' => '100%') do
            xml.thead do
              xml.tr do
                xml.th('Allergy')
                xml.th('Allergy ID')
                xml.th('Reaction')
                xml.th('Onset Date')
                xml.th('Note')
                xml.th('RxNorm Name')
                xml.th('RxNorm Code')
              end
            end
            xml.tbody do
              sorted_allergies.each do |allergy|
                xml.tr do
                  xml.td('rowspan' => '1') do
                    xml.content(allergy.allergen, 'ID' => "alert-#{allergy.id}")
                  end
                  # TODO: where do I get allergy ID?
                  xml.td('rowspan' => '1') do
                    xml.content('')
                  end
                  xml.td('rowspan' => '1') do
                    xml.content(allergy.reaction)
                  end
                  xml.td('rowspan' => '1') do
                    xml.content((allergy.start_date || allergy.create_date).strftime('%m/%d/%Y'))
                  end
                  xml.td('rowspan' => '1') do
                    xml.content(allergy.allergy_cause_notes)
                  end
                  # TODO: populate the database with RxNorm
                  imo_result = Imo.best_match(:allergy, allergy.allergen)
                  # TODO: RxNorm Name?
                  xml.td('rowspan' => '1') do
                    xml.content('')
                  end
                  xml.td('rowspan' => '1') do
                    if imo_result and imo_result[:rxnorm] and imo_result[:rxnorm][:code]
                      xml.content(imo_result[:rxnorm][:code])
                      rxnorm_codes[allergy.id] = imo_result[:rxnorm][:code]
                    else
                      xml.content('')
                    end
                  end
                end
              end
            end
          end
        end
        sorted_allergies.each do |allergy|
          xml.entry('contextConductionInd' => 'true', 'typeCode' => 'COMP') do
            xml.act('classCode' => 'ACT', 'typeCode' => 'EVN') do
              xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.27')
              xml.templateId('assigningAuthorityName' => 'HITSP/C83', 'root' => '2.16.840.1.113883.3.88.11.83.6')
              xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.4.5.3')
              xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.4.5.1')
              xml.id_
              xml.code_('nullFlavor' => 'NA')
              xml.statusCode('code' => 'active')
              xml.effectiveTime('xsi:type' => 'IVL_TS') do
                xml.low('value' => (allergy.start_date || allergy.create_date).strftime('%Y%m%d%H%M%S'))
              end
              xml.entryRelationship('contextConductionInd' => 'true', 'inversionInd' => 'false', 'typeCode' => 'SUBJ') do
                xml.observation('classCode' => 'OBS', 'moodCode' => 'EVN') do
                  xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.18')
                  xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.28')
                  xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.4.5')
                  xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.4.6')
                  xml.id_('root' => '1.2.3.4.5.3684')
                  xml.code_('code' => '419199007', 'codeSystem' => '2.16.840.1.113883.6.96', 'codeSystemName' => 'SNOMED CT', 'displayName' => 'Allergy to Substance (disorder)')
                  xml.statusCode('code' => 'completed')
                  xml.effectiveTime do
                    xml.low('value' => (allergy.start_date || allergy.create_date).strftime('%Y%m%d%H%M%S'))
                  end
                end
              end
              xml.value('code' => '106190000', 'codeSystem' => '2.16.840.1.113883.6.96', 'codeSystemName' => 'SNOMED CT', 'displayName' => 'Allergy', 'xsi:type' => 'CD')
              xml.informant('contextControlCode' => 'OP', 'typeCode' => 'INF') do
                xml.assignedEntity('classCode' => 'ASSIGNED') do
                  xml.id_
                  xml.addr('nullFlavor' => 'NI')
                  xml.telecom('nullFlavor' => 'NI')
                  xml.assignedPerson('classCode' => 'PSN', 'determinerCode' => 'INSTANCE') do
                    xml.name('nullFlavor' => 'UNK')
                  end
                  xml.representedOrganization('classCode' => 'ORG', 'determinerCode' => 'INSTANCE') do
                    xml.id_
                    xml.name('LifeQode, Inc')
                    xml.telecom('nullFlavor' => 'NI')
                    xml.addr('nullFlavor' => 'NI')
                  end
                end
              end
              xml.participant('contextControlCode' => 'OP', 'typeCode' => 'CSM') do
                xml.participantRole('classCode' => 'MANU') do
                  xml.addr('nullFlavor' => 'NI')
                  xml.telecom('nullFlavor' => 'NI')
                  xml.playingEntity('classCode' => 'MMAT', 'determinerCode' => 'INSTANCE') do
                    xml.code_('nullFlavor' => 'UNK') do
                      xml.originalText do
                        xml.reference('value' => 'alert-#{allergy.id}')
                      end
                    end
                    xml.name(allergy.allergen)
                  end
                end
              end
              xml.entryRelationship('contextConductionInd' => 'true', 'inversionInd' => 'false', 'typeCode' => 'REFR') do
                xml.observation('classCode' => 'OBS', 'moodCode' => 'EVN') do
                  xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.39')
                  xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.57')
                  xml.code_('code' => '33999-4', 'codeSystem' => '2.16.840.1.113883.6.1', 'codeSystemName' => 'LOINC', 'displayName' => 'Status')
                  xml.statusCode('code' => 'completed')
                  xml.value_('code' => '55561003', 'codeSystem' => '2.16.840.1.113883.6.96', 'codeSystemName' => 'SNOMED CT', 'displayName' => 'Active', 'xsi:type' => 'CD')
                end
              end
              # TODO: entryRelationship
            end
          end
        end
      end
    end
  end

  def self.to_ccd_diagnostic_results(xml, patient)
    xml.component('contextConductionInd' => 'true', 'typeCode' => 'COMP') do
      xml.section('classCode' => 'DOCSECT', 'moodCode' => 'EVN') do
        xml.templateId('root' => '2.16.840.1.113883.3.88.11.83.122')
        xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.14')
        xml.templateId('assigningAuthorityName' => 'HITSP/C32', 'root' => '2.16.840.1.113883.3.88.11.32.16')
        xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.3.28')
        xml.code('code' => '30954-2', 'codeSystem' => '2.16.840.1.113883.6.1', 'codeSystemName' => 'LOINC', 'displayName' => 'Relevant diagnostic tests and/or laboratory data')
        xml.title('Diagnostic Results')
        # TODO: figure out where to store diagnostic results
        xml.text_ do
          xml.table('border' => '1', 'width' => '100%') do
            xml.thead do
              xml.tr do
                xml.th('Result Name')
                xml.th('Observation Name')
                xml.th('Observation Value')
                xml.th('Onset Date')
                xml.th('Observation Units')
                xml.th('Normal Range')
                xml.th('Abnormal?')
                xml.th('Observation Time')
                xml.th('Observation LOINC')
              end
            end
            xml.tbody do
              xml.tr do
                xml.td('rowspan' => '1') do
                  xml.content('No Results Recorded', 'ID' => "result-0")
                end
                xml.td('rowspan' => '1') do
                  xml.content('ID' => 'nullobservation-result-0')
                end
                xml.td('rowspan' => '1') do
                  xml.content('')
                end
                xml.td('rowspan' => '1') do
                  xml.content('')
                end
                xml.td('rowspan' => '1') do
                  xml.content('')
                end
                xml.td('rowspan' => '1') do
                  xml.content('')
                end
                xml.td('rowspan' => '1') do
                  xml.content('')
                end
                xml.td('rowspan' => '1') do
                  xml.content('')
                end
              end
            end
          end
        end
        xml.entry('contextConductionInd' => 'true', 'typeCode' => 'COMP') do
          xml.organizer('classCode' => 'CLUSTER', 'typeCode' => 'EVN') do
            xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.32')
            xml.id_
            xml.code_('nullFlavor' => 'UNK') do
              xml.originalText do
                xml.reference(value='#result-0')
              end
            end
            xml.statusCode('code' => 'R')
            xml.effectiveTime('nullFlavor' => 'UNK')
            xml.component('contextConductionInd' => 'true', 'typeCode' => 'COMP') do
              xml.observation('classCode' => 'OBS', 'moodCode' => 'EVN') do
                xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.31')
                xml.templateId('assigningAuthorityName' => 'HISTP/C83', 'root' => '2.16.840.1.113883.3.88.11.83.15.1')
                xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.4.13')
                xml.id_
                xml.code_('code' => '0', 'displayName' => 'Result')
                xml.text_ do
                  xml.reference('value' => '#nullobservation-result-0')
                end
                xml.statusCode('code' => 'completed')
                xml.code_('nullFlavor' => 'UNK')
                xml.value('nullFlavor' => 'UNK', 'xsi:type' => 'CD')
              end
            end
            xml.component('contextConductionInd' => 'true', 'typeCode' => 'COMP') do
              xml.procedure('classCode' => 'PROC', 'moodCode' => 'EVN') do
                xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.29')
                xml.templateId('assigningAuthorityName' => 'HISTP/C83', 'root' => '2.16.840.1.113883.3.88.11.83.17')
                xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.4.19')
                xml.id_
                xml.code_('nullFlavor' => 'UNK') do
                  xml.originalText do
                    xml.reference(value='#result-0')
                  end
                end
                xml.text_ do
                  xml.reference('value' => '#result-0')
                end
                xml.statusCode('code' => 'completed')
                xml.effectiveTime('nullFlavor' => 'UNK')
              end
            end
          end
        end
      end
    end
  end

  def self.to_ccd_immunizations(xml, patient)
    xml.component('contextConductionInd' => 'true', 'typeCode' => 'COMP') do
      xml.section('classCode' => 'DOCSECT', 'moodCode' => 'EVN') do
        xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.6')
        xml.templateId('assigningAuthorityName' => 'HITSP/C32', 'root' => '2.16.840.1.113883.3.88.11.32.14')
        xml.templateId('assigningAuthorityName' => 'HITSP/C83', 'root' => '2.16.840.1.113883.3.88.11.83.117')
        xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.3.23')
        xml.code('code' => '11369-6', 'codeSystem' => '2.16.840.1.113883.6.1', 'codeSystemName' => 'LOINC', 'displayName' => 'History of immunizations')
        xml.title('Immunizations')

        immunizations = patient.patient_health_events.select { |event| event.health_event_type.eql?('IMMUNIZATION') }
        # currently sorting conditions based on create_date
        # TODO: populate start_date for conditions?
        sorted_immunizations = immunizations.sort_by {|event| event.create_date}
        snomed_codes = {}
        # TODO: add CVX column to the database and populate?
        cvx_codes = {}
        xml.text_ do
          xml.table('border' => '1', 'width' => '100%') do
            xml.thead do
              xml.tr do
                xml.th('Genus Name (Administered Vaccines)')
                xml.th('Administration Date')
                xml.th('Lot #')
                xml.th('Manufacturer')
                xml.th('CVX Code')
              end
            end
            xml.tbody do
              sorted_immunizations.each do |immunization|
                xml.tr do
                  xml.td('rowspan' => '1') do
                    xml.content("#{immunization.health_event}", 'ID' => "vaccine-#{immunization.id}")
                  end
                  xml.td('rowspan' => '1') do
                    xml.content((immunization.start_date || immunization.create_date).strftime('%m/%d/%Y'))
                  end
                  xml.td('rowspan' => '1') do
                    xml.content('')
                  end
                  xml.td('rowspan' => '1') do
                    xml.content('')
                  end
                  # TODO: figure out how to populate CVX code
                  imo_result = Imo.best_match(:immunization, immunization.health_event)
                  xml.td('rowspan' => '1') do
                    if imo_result and imo_result[:cvx] and imo_result[:cvx][:code]
                      xml.content(imo_result[:cvx][:code])
                      cvx_codes[immunization.id] = imo_result[:cvx][:code]
                    else
                      xml.content('')
                    end
                  end
                end
              end
            end
          end
        end
        sorted_immunizations.each do |immunization|
          xml.entry('contextConductionInd' => 'true', 'typeCode' => 'DRIV') do
            xml.substanceAdministration('classCode' => 'SBADM', 'moodCode' => 'EVN', 'negationInd' => 'false') do
              xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.24')
              xml.templateId('assigningAuthorityName' => 'HISTP/C83', 'root' => '2.16.840.1.113883.3.88.11.83.13')
              xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.4.12')
              xml.id_
              xml.code_('code' => 'IMMUNIZ', 'codeSystem' => '2.16.840.1.113883.5.4', 'codeSystemName' => 'ActCode')
              xml.text_ do
                xml.reference('value' => "#vaccine-#{immunization.id}")
              end
              xml.statusCode('code' => 'completed')
              xml.effectiveTime('value' => (immunization.start_date || immunization.create_date).strftime('%Y%m%d%H%M%S'))
              xml.routeCode('nullFlavor' => 'UNK')
              xml.doseQuantity('nullFlavor' => 'UNK')
              xml.consumable('typeCode' => 'CSM') do
                xml.manufacturedProduct('classCode' => 'MANU') do
                  xml.templateId('assigningAuthorityName' => 'CCD', 'root' => '2.16.840.1.113883.10.20.1.53')
                  xml.templateId('assigningAuthorityName' => 'HISTP/C83', 'root' => '2.16.840.1.113883.3.88.11.83.8.2')
                  xml.templateId('assigningAuthorityName' => 'IHE', 'root' => '1.3.6.1.4.1.19376.1.5.3.1.4.7.2')
                  xml.manufacturedMaterial('classCode' => 'MMAT', 'determinerCode' => 'KIND') do
                    # TODO: figure out CVX code
                    xml.code('code' => cvx_codes[immunization.id], 'codeSystem' => '2.16.840.1.113883.6.59', 'codeSystemName' => 'Codes for Vaccine Administered', 'displayName' => immunization.health_event) do
                      xml.originalText do
                        xml.reference('value' => "#vaccine-#{immunization.id}")
                      end
                    end
                    xml.lotNumberText('')
                  end
                  xml.manufacturerOrganization('classCode' => 'ORG', 'determinerCode' => 'INSTANCE') do
                    xml.name('')
                  end
                end
              end
              xml.informant('contextControlCode' => 'OP', 'typeCode' => 'INF') do
                xml.assignedEntity('classCode' => 'ASSIGNED') do
                  xml.id_
                  xml.addr('nullFlavor' => 'NI')
                  xml.telecom('nullFlavor' => 'NI')
                  xml.assignedPerson('classCode' => 'PSN', 'determinerCode' => 'INSTANCE') do
                    xml.name('nullFlavor' => 'UNK')
                  end
                  xml.representedOrganization('classCode' => 'ORG', 'determinerCode' => 'INSTANCE') do
                    xml.name('LifeQode, Inc')
                    xml.telecom('nullFlavor' => 'NI')
                    xml.addr('nullFlavor' => 'NI')
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def self.to_ccd_procedures(xml, patient)
    nil
  #     <component contextConductionInd="true" typeCode="COMP">
  #       <section classCode="DOCSECT" moodCode="EVN">
  #         <templateId assigningAuthorityName="CCD" root="2.16.840.1.113883.10.20.1.12" />
  #         <templateId assigningAuthorityName="HITSP/C83" root="2.16.840.1.113883.3.88.11.83.108" />
  #         <templateId assigningAuthorityName="HITSP/C32" root="2.16.840.1.113883.3.88.11.32.18" />
  #         <templateId assigningAuthorityName="IHE" root="1.3.6.1.4.1.19376.1.5.3.1.3.12" />
  #         <templateId assigningAuthorityName="IHE" root="1.3.6.1.4.1.19376.1.5.3.1.3.11" />
  #         <code code="47519-4" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="History of procedures" />
  #         <title>Procedures</title>
  #         <text>
  #           <table border="1" width="100%">
  #             <thead>
  #               <tr>
  #                 <th>Procedure Name</th>
  #                 <th>Procedure Date</th>
  #                 <th>CPT Code</th>
  #                 <th>Performing Provider</th>
  #               </tr>
  #             </thead>
  #             <tbody>
  #               <tr>
  #                 <td rowspan="1">
  #                   <content ID="surgery-2683">Cholecystectomy</content>
  #                 </td>
  #                 <td rowspan="1">
  #                   <content>07/13/2014</content>
  #                 </td>
  #                 <td rowspan="1">
  #                   <content />
  #                 </td>
  #                 <td rowspan="1">
  #                   <content />
  #                 </td>
  #               </tr>
  #               <tr>
  #                 <td rowspan="1">
  #                   <content ID="surgery-2682">Appendectomy</content>
  #                 </td>
  #                 <td rowspan="1">
  #                   <content>07/07/2008</content>
  #                 </td>
  #                 <td rowspan="1">
  #                   <content />
  #                 </td>
  #                 <td rowspan="1">
  #                   <content />
  #                 </td>
  #               </tr>
  #             </tbody>
  #           </table>
  #         </text>
  #         <entry contextConductionInd="true" typeCode="COMP">
  #           <procedure classCode="PROC" moodCode="EVN">
  #             <templateId assigningAuthorityName="CCD" root="2.16.840.1.113883.10.20.1.29" />
  #             <templateId assigningAuthorityName="HITSP/C83" root="2.16.840.1.113883.3.88.11.83.17" />
  #             <templateId assigningAuthorityName="IHE" root="1.3.6.1.4.1.19376.1.5.3.1.4.19" />
  #             <id />
  #             <code nullFlavor="UNK">
  #               <originalText>
  #                 <reference value="#surgery-2683" />
  #               </originalText>
  #             </code>
  #             <text>
  #               <reference value="#surgery-2683" />
  #             </text>
  #             <statusCode code="completed" />
  #             <effectiveTime value="20140713000000" />
  #             <targetSiteCode />
  #             <informant contextControlCode="OP" typeCode="INF">
  #               <assignedEntity classCode="ASSIGNED">
  #                 <id />
  #                 <addr nullFlavor="NI" />
  #                 <telecom nullFlavor="NI" />
  #                 <assignedPerson classCode="PSN" determinerCode="INSTANCE">
  #                   <name nullFlavor="UNK" />
  #                 </assignedPerson>
  #                 <representedOrganization classCode="ORG" determinerCode="INSTANCE">
  #                   <name>MDP Test - Life Square 1959002</name>
  #                   <telecom nullFlavor="NI" />
  #                   <addr nullFlavor="NI" />
  #                 </representedOrganization>
  #               </assignedEntity>
  #             </informant>
  #           </procedure>
  #         </entry>
  #         <entry contextConductionInd="true" typeCode="COMP">
  #           <procedure classCode="PROC" moodCode="EVN">
  #             <templateId assigningAuthorityName="CCD" root="2.16.840.1.113883.10.20.1.29" />
  #             <templateId assigningAuthorityName="HITSP/C83" root="2.16.840.1.113883.3.88.11.83.17" />
  #             <templateId assigningAuthorityName="IHE" root="1.3.6.1.4.1.19376.1.5.3.1.4.19" />
  #             <id />
  #             <code nullFlavor="UNK">
  #               <originalText>
  #                 <reference value="#surgery-2682" />
  #               </originalText>
  #             </code>
  #             <text>
  #               <reference value="#surgery-2682" />
  #             </text>
  #             <statusCode code="completed" />
  #             <effectiveTime value="20080707000000" />
  #             <targetSiteCode />
  #             <informant contextControlCode="OP" typeCode="INF">
  #               <assignedEntity classCode="ASSIGNED">
  #                 <id />
  #                 <addr nullFlavor="NI" />
  #                 <telecom nullFlavor="NI" />
  #                 <assignedPerson classCode="PSN" determinerCode="INSTANCE">
  #                   <name nullFlavor="UNK" />
  #                 </assignedPerson>
  #                 <representedOrganization classCode="ORG" determinerCode="INSTANCE">
  #                   <name>MDP Test - Life Square 1959002</name>
  #                   <telecom nullFlavor="NI" />
  #                   <addr nullFlavor="NI" />
  #                 </representedOrganization>
  #               </assignedEntity>
  #             </informant>
  #           </procedure>
  #         </entry>
  #       </section>
  #     </component>
  #   </structuredBody>
  # </component>
  end

end
