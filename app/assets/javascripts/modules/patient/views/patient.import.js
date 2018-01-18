(function (Patient, Utilities) {
    "use strict";

    Patient.Views.Importer = Backbone.View.extend({
        
        events: {
            'change input[name="mode"]': 'toggleMode',
            'change select[name="emr_id"]': 'toggleEmr',
            
            // actions
            'click a#import-records': 'queryEmr',
            'click a#upload-records': 'uploadFile',
            
            'click .cancel-import-records': 'actionCancel'

        },

        initialize: function() {
            // scope and bind your methods, sucka
            _.bindAll(this, 'actionCancel', 'toggleMode', 'toggleEmr', 'queryEmr', 'uploadFile', '_uploadFile', 'resetImportView', 'resetUploadView');
            
            this.API_ENDPOINT_PULL = $(this.$el).attr('data-action');
            this.API_ENDPOINT_UPLOAD = $(this.$el).attr('data-action-upload');
            this.PATIENT_ID = $(this.$el).attr('data-patient-uuid');

            this.locked = false;
            this.ccd_file = null;
        },

        toggleMode: function(e){
            var v = $(e.currentTarget).val();
            if(v == 'pull'){
                $('#importer-pull').show();
                $('#importer-upload').hide();
            }
            if(v == 'upload'){
                $('#importer-pull').hide();
                $('#importer-upload').show();
            }
        },

        toggleEmr: function(e){
            if($(e.currentTarget).val() != ''){
                this.$el.find('.step2').slideDown();
            }
        },

        queryEmr: function(e){
            var scope = this;
            var payload = {
                'FirstName': this.$el.find('input[name="first_name"]').val(),
                'LastName': this.$el.find('input[name="last_name"]').val(),
                'EmrId': this.$el.find('select[name="emr_id"]').val(),
                'Phone': this.$el.find('input[name="phone"]').val(),
                'DOB': this.$el.find('input[name="dob"]').val(),
                'SSN': this.$el.find('input[name="ssn"]').val()
            };

            if(payload.EmrId == '' || payload.EmrId == undefined){
                app.alert('Must select EMR');
                return;
            }

            $('#import-records').addClass('disabled').attr('disabled', 'disabled').text('Loading…');

            $.ajax({
                url: scope.API_ENDPOINT_PULL,
                type: 'POST',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(payload),
                // 200 for a match, and to kick the subsequent state of processing
                success: function(data){
                    $('#import-records').removeClass('disabled');
                    $('#emr-form').slideUp();
                    $('#import-modal .success-message').slideDown();
                    $('#importer-decision-tree-alpha').slideUp();
                },

                // 404 for no patient found

                // 500 for multiple patients (TODO: better status code)
                error: function(data){

                    if(data.status == 400){
                        app.alert('Bad request: Invalid EMR, please select from the available options.');
                        scope.resetImportView();
                    }

                    if(data.status == 404){
                        app.alert('No patient found, please double check information and try again');
                        scope.resetImportView();
                    }
                    if(data.status == 409){
                        app.alert('Multiple patients found, please contact Lifesquare Customer Support for assistance.');
                        // UI to offer disambiguation here
                        scope.resetImportView();
                    }
                    if(data.status == 500){
                        app.alert('Import has failed!');
                        scope.resetImportView();
                    }
                }
            });

        },

        uploadFile: function(e){
            // meh
            $('#upload-records').addClass('disabled').attr('disabled', 'disabled').text('Loading…');

            var f = $('#patient_ccd').get(0).files[0];
            var scope = this;
            $.when(Utilities.Data.convertFileToBase64(f, f.name)).then(
                function(r){
                    scope._uploadFile(r);
                }
            );

        },

        _uploadFile: function(data){
            var scope = this;
            $.ajax({
                url: scope.API_ENDPOINT_UPLOAD,
                type: 'POST',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify({
                    'CCD': data
                }),
                // 200 for a match, and to kick the subsequent state of processing
                success: function(data){
                    $('#importer-upload').slideUp();
                    $('#import-modal .success-message').slideDown();
                    $('#importer-decision-tree-alpha').slideUp();
                },

                error: function(data){

                    if(data.status == 400){
                        app.alert('Bad request: Invalid CCD.');
                        scope.resetUploadView();
                    }

                    if(data.status == 500){
                        app.alert('Import has failed!');
                        scope.resetUploadView();
                    }
                }
            });
        },

        resetImportView: function(){
            $('#import-records').removeClass('disabled').removeAttr('disabled').text('Begin Import');
            $('#emr-form').slideDown();
            $('#import-modal .success-message').hide();
        },

        resetUploadView: function(){
            $('#upload-records').removeClass('disabled').removeAttr('disabled').text('Begin Import');
            $('#import-modal .success-message').hide();
        },

        actionCancel: function(e){
            $('#import-modal').trigger('reveal:close');
        }

    });

}(app.module('patient'), app.module('utilities')));