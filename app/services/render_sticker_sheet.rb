require 'open3'
require 'json'
# we could remove this here if we passed it up and in from the outside son,
# but whatever, there is already a ton of tight coupling

class RenderStickerSheet

    def self.call(code_sheet_print_request)
        # init data storage
        print_data = {
            :lifesquares => []
        }

        # generic instructions or perlifesquare instructions?

        # break apart the lifesquares csv
        lifesquare_codes = code_sheet_print_request.lifesquares.split(',')
        lifesquare_codes.each do |lifesquare_uid|
            rendered = self.pre_render_lifesquare(
                lifesquare_uid.strip.gsub(" ", ""), # we have user entered data, so trim it down
                code_sheet_print_request.get_printable_address,
                code_sheet_print_request.reprint,
                code_sheet_print_request.instructions
            )
            # TODO: validation though?
            code_sheet_print_request.sheets_per_lifesquare.times do |n|
                print_data[:lifesquares].push(rendered)
            end
        end

        code_sheet_print_request.print_data = print_data.to_json
        code_sheet_print_request.status = 1# AKA model.enum.STATUS_SPECCED
        code_sheet_print_request.save
        # there is no longer a valid item.status = STATUS_UNKNOWN_PATIENT because each request is more than one patient, w/e son

        # handoff to pdf gen service, command line arg with the deets
        # for the print request or whatever holds the json data
        # TODO: capture standard output from node with a pdf base64 encoded data stream
        # then convert and pipe into S3
        cspr_id = code_sheet_print_request.code_sheet_print_request_id
        api_endpoint = Rails.application.routes.url_helpers.api_print_data_url(cspr_id)
        if Rails.env == 'development'
            # GHETTO MAX HACKXX FOR local "multi-threading"
            api_endpoint = 'http://localhost:3001' + Rails.application.routes.url_helpers.api_print_data_path(cspr_id)
        end

        key = code_sheet_print_request.get_s3_storage_path()
        Open3.popen3('nodejs', 'script/render_stickers_pdf.js',
            api_endpoint,
            key,
            :chdir=>Rails.root.to_s) do |i,o,e,t|
                # o.gets
                # e.gets
                puts e.read
                return key
            end
        return nil
    end

private

    def self.pre_render_lifesquare(lifesquare_uid, address, reprint, instructions)
        # lookup the lifesquare database object
        # be case-sensitive or not? consider state, naaaaaaa
        lifesquare = Lifesquare.where(:lifesquare_uid => lifesquare_uid).first
        campaign = nil
        if lifesquare != nil
            output = IO.popen("qrencode -v2 -m0 -s1 -t ASCII https://lsqr.net/#{lifesquare.lifesquare_uid}")
            if output
                # lookup patient now
                obj = {
                    :lifesquare => lifesquare.lifesquare_uid,
                    :qr => output.readlines.join[0..-2]
                }
                if lifesquare.patient_id and patient = Patient.where(:patient_id => lifesquare.patient_id).first
                    printable_address = address
                    if address == ""
                        printable_address = patient.get_printable_address
                    end
                    if patient.confirmed?
                        obj[:name] = patient.fullname
                        obj[:dob] = patient.dob_to_s_slashes
                        obj[:address] = printable_address
                    else
                    end
                    campaign = patient.has_active_campaign                    
                else
                    if lifesquare.campaign != nil
                        campaign = lifesquare.campaign
                    end
                end
                if campaign != nil
                    begin
                        org = Organization.find(campaign.organization_id)
                        if org.name
                            obj[:org] = org.name
                        end
                        if org.ls_name
                            obj[:org] = org.ls_name
                        end
                    rescue
                        # do nothing
                    end
                end
                if instructions != nil
                    # TODO: opportunity to use templating to interpret for personalization if that's a thing
                    obj[:instructions] = instructions
                end
                return obj
            else
                return nil
            end
        else
            return nil
        end
    end

end
