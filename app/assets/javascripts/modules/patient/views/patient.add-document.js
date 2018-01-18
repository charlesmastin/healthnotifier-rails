(function (Patient, Utilities) {
    "use strict";

    Patient.Views.AddDocument = Backbone.View.extend({

        // TODO: restrict input to jpeg, jpg, png
        
        events: {
            // file input related
            'drop .drop-target': 'onDrop',
            'dragover .drop-target': 'onDragOver',
            'dragenter .drop-target': 'onDragOver',
            'dragleave .drop-target': 'onDragLeave',
            'change .photo-file': 'addFiles',

            // remove the individual file, if exists            

            // actions
            'click .action-save': 'actionSave',
            'click .action-remove-page': 'actionRemovePage', // will need to redelegate all the events to be "live"
            'click .action-cancel': 'actionCancel'
        },

        initialize: function(options) {
            
            // scope and bind your methods, sucka
            _.bindAll(this, 'actionRemovePage');

            this.parsedFiles = [];
            this.API_ENDPOINT = $(this.$el).attr('data-endpoint');
            this.locked = false;

            // have we even been rendered yet, damn son
            var sel = this.$el.find('select[name="document_type"]');
            sel.empty();
            sel.val('');
            var document_types = [{name: '', value:''}];

            if(options.mode == 'directive'){
                document_types = document_types.concat(window.DIRECTIVE_VALUES);
                this.$el.find('h2.title').html('Add Directive');
                this.$el.find('label[for="add-document-document-type"]').html('Directive Type');
            }
            if(options.mode == 'document'){
                document_types = document_types.concat(window.DOCUMENT_VALUES);
                this.$el.find('h2.title').html('Add Document');
                this.$el.find('label[for="add-document-document-type"]').html('Document Type');
            }
            // TODO: when we gut the front-end use babel or whatever to transpile yourself silly
            // this will do for now
            _.each(document_types, function(item){
                sel.append($('<option>', {value:item.value, text:item.name}));
            });

            // set a default privacy to Provider sucka
            this.$el.find('select[name="privacy"]').val('provider');

            var scope = this;


            
        },

        addFiles: function(e){
            try {
                for(var i=0; i<e.target.files.length; i++){
                    var file = e.target.files[i];
                    this.addFile({file: file, filename: file.name});
                }
            } catch(e){
                console.log(e);
            }
        },

        addFile: function(data){
            var scope = this;

            if(data.file != undefined){
                // store it son

                // are we a pdf, we can't render screens of this, so we need a special case
                // cheap pattern matching on available file input types
                // TODO: add some double shots SWAT validation on it
                var name = data.filename.toLowerCase();
                // var ext = '' vs containts .endsWith not avail for IE, w/e
                if(name.indexOf('.jpg') != -1 || name.indexOf('.jpeg') != -1 || name.indexOf('.png') != -1){
                    $.when(Utilities.Data.convertFileToBase64(data.file, data.filename)).then(
                        function(r){
                            scope.parsedFiles.push(r);
                            // templates are better, lol, but this works
                            scope.$el.find('section.files').append($('<article><img src="data:image/jpeg;base64' + r.File + '" /><a href="#" class="action-remove-page"><i class="material-icons">remove_circle</i></a><small>' + data.filename + '</small></article>'));
                        }
                    );
                } else if (name.indexOf('.pdf')){
                    $.when(Utilities.Data.convertFileToBase64(data.file, data.filename)).then(
                        function(r){
                            scope.parsedFiles.push(r);
                            scope.$el.find('section.files').append($('<article class="pdf"><div class="icon"><i class="material-icons">picture_as_pdf</i></div><a href="#" class="action-remove-page"><i class="material-icons">remove_circle</i></a><small>' + data.filename + '</small></article>'));
                        }
                    );
                } else {
                    app.alert('Invalid File: Please add jpg, png, or pdf');
                }                
            }

            this.delegateEvents();
        },
        
        displayError: function(e){
            this.unlockInteraction();
            this.$el.find('.error-message').empty().html(e.message).show();
        },

        onDrop: function(e){
            e.preventDefault();
            e.stopPropagation();
            this.$el.find('.drop-target').removeClass('over');
            e.dataTransfer = e.originalEvent.dataTransfer;
            try {
                for(var i=0; i<e.dataTransfer.files.length; i++){
                    var file = e.dataTransfer.files[i];
                    if(_.contains(["image/png", "image/jpeg", "application/pdf"], file.type)){
                        this.addFile({file: file, filename: file.name});
                    }else {
                        app.alert('Unsupported filetype. Please add jpg, png, or pdf!');
                    }
                }

            } catch(e){                
                console.log(e);
            }

            return false;
        },

        onDragOver: function(e){
            this.$el.find('.drop-target').addClass('over');
            e.preventDefault();
        },

        onDragLeave: function(e){
            this.$el.find('.drop-target').removeClass('over');
        },

        actionRemovePage: function(e){
            // get that index son
            if(this.locked){
                return false;
            }

            var index = $(e.currentTarget).parent().index();
            $(e.currentTarget).parent().fadeOut(function(){
                $(this).remove();
            });
            this.parsedFiles.splice(index, 1);

            return false;
        },

        actionSave: function(e){
            // TODO: perform validations
            if(this.$el.find('select[name="document_type"]').val() == ''){
                app.alert('Please select document type');
                return;
            }
            if(this.parsedFiles.length == 0){
                app.alert('Please add at least one file');
                return;
            }
            // not sure of the width and height in pixels, so we dodge the crop params. sucka
            // set UI state
            if(this.locked){
                return;
            }
            var scope = this;
            var payload = {
                Privacy: this.$el.find('select[name="privacy"]').val(),
                DirectiveType: this.$el.find('select[name="document_type"]').val(),
                PatientId: this.$el.attr('data-patient-uuid'),
                Files: this.parsedFiles
            }
            this.lockInteraction();
            
            // if we had a crop, we would send that as well
            $.ajax({
                url: scope.API_ENDPOINT,
                type: 'POST',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(payload),
                success: function(data){
                    $(document).trigger('onDocumentUploadState', ['update', data]);
                    scope.destroy();
                },
                error: function(error){
                    scope.displayError(error);
                }
            });
            
            return false;
        },

        actionCancel: function(e){
            if(this.locked){
                return;
            }
            $(document).trigger('onDocumentUploadState', 'cancel');
            this.destroy();
        },

        destroy: function(){
            // wipe UI state
            this.$el.find('.files').empty();
            this.parsedFiles = [];


            this.unlockInteraction();
            // clean it up son
            this.undelegateEvents();
            this.$el.removeData().unbind(); 

            // Remove view from DOM
            // this.remove();
            // Backbone.View.prototype.remove.call(this);
        },

        lockInteraction: function(){
            this.locked = true;
            this.$el.find('a.action-save').text('Saving…');
        },

        unlockInteraction: function(){
            this.locked = false;
            this.$el.find('a.action-save').text('Save');
        }

    });

}(app.module('patient'), app.module('utilities')));