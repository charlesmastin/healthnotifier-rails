module Api
  class DocumentsController < Api::ApplicationController
    before_action :authenticate_account, except: [:retrieve_file]
    before_action :establish_document, only: [:get, :update, :delete]

    def get
      # TODO: start thinking about dem before_action decorators for this common sludge piles
      view_permission = @pha.patient.view_permission_for_account(@account)
      if !Patient::obj_has_view_permission(@pha, view_permission)
        render json: {
          :success => false,
          :message => "Permission Denied"
        }, status: 403
        return
      end

      files = []
      @dd.document_digitized_files.each_with_index do |digitized_file, i|
        # build it out as we've done so many places, ideally doh, this becomes pretty DRY across our platform
        files.push({
          :Uid => digitized_file.uid,
          :Part => i,
        })
      end

      owner = false
      # who dat owner? you dat owner? or better yet - 
      # is the patient of the pha, one of your patients
      # TODO: canonical way to check if auth_account patients intersect with a patiend_id
      # this is terrrrrrrrible, Jerry.... help!
      ap = Patient.where(:account_id => @account.account_id, :patient_id => @pha.patient_id).first
      if ap != nil
        owner = true
      end

      # TODO: hook into the PatientNetwork to check permissions

      # jimmy jack the full base url up in there, probably millions of ways to do it
      @baseurl = request.protocol + request.host_with_port
      @controls = false
      html = render_to_string(:layout => false, :formats => [:html], :template => 'api/documents/collection_view')
      # build a structure of data
      j = {
        :Title => @dd.title != nil && @dd.title != "" ? @dd.title : @dd.category,
        :Category => @dd.category,
        :Files => files,
        :Privacy => @pha.privacy,
        :Owner => owner,
        :CreateDate => @pha.create_date,
        :LastUpdate => @pha.last_update,
        :Uid => @dd.uid,
        :Html => html
      }

      render :json => j
    end

    def create
      # TODO: become fault tolerant, more than brute force failzones, although that's probably already handled somewhere, ugg, ugg
      # TODO: use proper handling of auth_check
      

      begin
        patient = Patient.where(:account_id => @account.account_id, :uuid => params[:PatientId], :status => 'ACTIVE').first
        if patient == nil
          render json: {
            :success => false,
            :message => "Permission Denied: Must Be Owner"
          }, status: 403
          return
        end
        # TODO: further auth checks to ensure we own the patient, although the likelihood of hacking using uuid is slim

        document_info = {}
        document_info['category'] = params[:DirectiveType]
        document_info['files'] = []
        # Deal with new style API attribute names (should automate this somewhere)
        params[:Files].each do |file|
          document_info['files'].push({
            'file' => file['File'],
            'name' => file['Name'],
            'mimetype' => file['Mimetype']
          })
        end

        document_digitized = UploadDocumentDigitized.call(document_info)
        converted_document_digitized = ConvertDocumentDigitized.call(document_digitized)

        # BAKE INTO JERRY'S STUFFS SON
        if params[:Title] != nil
          converted_document_digitized.title = params[:Title]
          converted_document_digitized.save
        end

        patient_health_attribute = PatientHealthAttribute.new
        patient_health_attribute.value = document_digitized.id.to_s
        patient_health_attribute.create_user = @account.account_id
        patient_health_attribute.update_user = @account.account_id
        patient_health_attribute.document_digitized = converted_document_digitized



        # LOL DOWNCASE YOURSELF SILLY OH FREAKING HELL
        patient_health_attribute.privacy = params[:Privacy].downcase

        patient.patient_health_attributes << patient_health_attribute
        patient.save!

        

        # file type validation with mimetype + imagemagic

        # tap some code from patient_controller and the services, lolzors

        # return a basic 200 to fake things for now

        # TODO: improve on this

        begin
          doc = {
            :success => true,
            :DocumentUuid => converted_document_digitized.uid.to_s,
            :DocumentType => converted_document_digitized.category,
            :Privacy => patient_health_attribute.privacy,
            :FirstChildUuid => converted_document_digitized.document_digitized_files[0].uid.to_s,
            :Size => converted_document_digitized.document_digitized_files.count
          }
        rescue Exception => e
          # do nothing to save it
          doc = {:success => true}
        end

        render :json => doc

      rescue Exception => e
        render json: {
          :success => false,
          :message => "An unknown failure occured"
        }, status: 500
      end
    end

    def delete
      # TODO: owner check

      # actually enforce on dat auth check son
      # TODO: move to a single Document Endpoint, SON
      begin        
        if @pha != nil
          # owner check now good sir
          owner = false

          # TODO: require owner on object 
          patient = Patient.where(:account_id => @account.account_id, :patient_id => @pha.patient_id).first

          if patient != nil
            @pha.document_digitized = nil
            @pha.value = 'NONE'
            @dd.destroy
            # iterate all the children file objects OMG bake that into the dd destroy method, hopefully
            @pha.destroy
            begin
              flash[:notice] = 'Document Successfully Deleted'
            rescue

            end
          else
            render json: {
              :success => false,
              :message => "Permission Denied: Must be owner"
            }, status: 403
            return
          end
        else
          render json: {
            :success => false,
            :message => "Document Not Found"
          }, status: 404
          return
        end

        render :json => {:success=>true}
      rescue
        render json: {
          :success => false,
          :message => "An unknown failure occured while attempting to delete"
        }, status: 500
      end


      # handle errors
    end

    # this is really a misnamed guy here, but it's setup for the futures
    # via patch
    def update
      # permissable attrs are
      # privacy, category, user label, blablabla
      @pha.privacy = params[:Privacy].downcase

      # lol son
      if params[:Title] != nil
        @dd.title = params[:Title]
      end
      if params[:Category] != nil
        @dd.category = params[:Category]
      end

      if @pha.save && @dd.save
        render :json => {:success=>true}
      else
        render :json => {
          :success => false,
          :message => 'Bad Request'
        }, status: 400 
      end
    end

    def collection_view
      # TODO: check ownership for permission, 

      # TODO: REMOVE THIS VIEW, it was only used for legacy mobile webview :)
      # backport ok
      id = Base64.urlsafe_decode64(params[:uid])
      # TODO: auth check on this bizzle? this is relatively insecure
      @dd = DocumentDigitized.where(:document_digitized_id => id).first

      if @dd == nil
        render json: {
          :success => false,
          :message => "Document not found"
        }, status: 404
        return
      end

      @pha = PatientHealthAttribute.where(:document_digitized_id => id ).first

      return render(:layout => false)
    end

    def retrieve_file
      # ADD BACK DAT AUTH SON, KINDA IMPORTANT, we could jimmy rig with get variables or something
      begin
        uid = Base64.urlsafe_decode64(params[:uid])
        # TODO: avoid hitting db by storing json of the crap in redis, lol lol oh lol
        mime_types = {"JPG" => "image/jpeg", "PNG" => "image/png", "PDF" => "application/pdf"}
        f = DocumentDigitizedFile.where(:digitized_file_uid => uid).first
        mime_type = mime_types[f.file_format] || "application/octet-stream"
        data = OrientDocumentDigitized.call(S3Download.call(f.digitized_file_uid))
        # using the mimetype or whatever, create a response and stream/write the file back to the client

        # HOOK YOUR HOOKS FOR DA THUMBNAILZZZZZ SON
        if params[:width] != nil and params[:height] != nil
          img = Magick::Image.from_blob(data).first
          img.crop_resized!(params[:width].to_i, params[:height].to_i)
          data = img.to_blob { self.format = 'JPG' }
        end

        send_data data, :type=> mime_type, :filename => f.file_spec, :disposition => :inline
        return
      rescue
        render nothing:true, status: 404
      end
    end

    private

  def establish_document
    id = Base64.urlsafe_decode64(params[:uid])
    @dd = DocumentDigitized.where(:document_digitized_id => id).first
    @pha = PatientHealthAttribute.where(:document_digitized_id => id).first
  end

  end
end