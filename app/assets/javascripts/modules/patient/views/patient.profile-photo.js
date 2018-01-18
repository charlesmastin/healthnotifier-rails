(function (Patient, Utilities) {
    "use strict";

    Patient.Views.ProfilePhotoEditor = Backbone.View.extend({

        // TODO: restrict input to jpeg, jpg, png
        
        events: {
            // file input related
            'drop .drop-target': 'onDrop',
            'dragover .drop-target': 'onDragOver',
            'dragenter .drop-target': 'onDragOver',
            'dragleave .drop-target': 'onDragLeave',
            'change .photo-file': 'addFile',
            // actions
            'click .action-save': 'actionSave',
            'click .action-remove': 'actionRemove',
            'click .action-cancel': 'actionCancel'
        },

        initialize: function() {
            // scope and bind your methods, sucka
            _.bindAll(this, 'applyCropper', 'changeCrop');

            this.parsedFile = null;
            this.crop = null;
            this.API_ENDPOINT = $(this.$el).attr('data-endpoint');
            this.existing_image = false;
            this.locked = false;
            this.dirty = false;
            this.cropper = null;
            this.Crop = null;

            // do we have an existing photo & croptown, sa
            // this is straddling the line between relying on the model and not
            if($(this.$el).attr('data-existing-photo')){
                this.existing_image = true;
                this.Crop = this.model.photo_thumb_crop_params_object();
                this.displayImage({url: this.API_ENDPOINT });   
            }
        },

        addFile: function(e){
            try {
                this.displayImage({file: e.target.files[0], filename: e.target.files[0].name});
            } catch(e){
                console.log(e);
            }
        },

        displayImage: function(data){
            var t = this.$el.find('.photo-viewer');
            t.empty();
            var scope = this;

            if(data.url != undefined){
                t.append($('<img src="' + data.url + '" />'));
            }

            if(data.file != undefined){
                // store it son
                t.append($('<img />'));
                $.when(Utilities.Data.convertFileToBase64(data.file, data.filename)).then(
                    function(r){
                        scope.parsedFile = r;
                        scope.$el.find('.photo-viewer img').attr('src', 'data:image/jpeg;base64' + scope.parsedFile.File);
                    }
                );
            }

            var img = $(t.find('img'));
            img.on('load', function(e) {
                scope.applyCropper(img);
            });

            // TODO: error check a bit better

            t.show();

            // hide the drop targets
            this.$el.find('.drop-target').hide();
            this.$el.find('.action-remove').css({'display': 'inline-block'});
        },

        applyCropper: function(img) {
            var options = {
                cornerHandles: true,
                sideHandles: true,
                aspectRatio: 1,
                boxWidth: 480,
                bgOpacity: .5,
                borderOpacity: .95,
                minSize: [128, 128],
                onChange: this.changeCrop,
                onSelect: this.changeCrop
            }
            this.cropper = $.Jcrop(img, options);
            var selection = [];
            if(this.Crop != null || this.Crop != undefined){
                selection = [
                    this.Crop.OriginX,
                    this.Crop.OriginY,
                    this.Crop.Width,
                    this.Crop.Height
                ];
            } else {
                // set up some default crop tacular boudning boxes, based on image size
                // this is a straight port from the OG code, thanks AY™
                var bounds = this.cropper.getBounds(),
                        pad = 40,
                        boxWidth = this.cropper.getOptions().boxWidth,
                        smallestSide = Math.min(bounds[0], bounds[1]),
                        maxDim = Math.floor(smallestSide - (2 * (smallestSide/boxWidth) * pad)),
                        left = (bounds[0]/2) - (maxDim/2),
                        top = (bounds[1]/2) - (maxDim/2);
                selection = [left, top, left + maxDim, top + maxDim];
            }
            if(selection.length == 4){
                this.cropper.setSelect(selection);
            }
        },

        changeCrop: function(coords) {
            this.Crop = {
                Width: coords.w,
                Height: coords.h,
                OriginX: coords.x,
                OriginY: coords.y
            }
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
                if(_.contains(["image/png", "image/jpeg"], e.dataTransfer.files[0].type)){
                    this.displayImage({file: e.dataTransfer.files[0], filename: e.dataTransfer.files[0].name});
                }else {
                    window.alert('Unsupported filetype. Please add jpg or png');
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

        actionRemove: function(e){
            if(this.locked){
                return;
            }
            if(e != undefined){
                // user interaction to remove file, vs mopup state call, lol, that's a clear indicaton
                // this method is doing too many things and being overloaded
                this.dirty = true;
            }
            this.parsedFile = null;
            this.Crop = null;
            // restore state, vis swap
            this.$el.find('.drop-target').show();
            this.$el.find('.photo-viewer').empty().hide();
            this.$el.find('.action-remove').hide();

            return false;
        },

        actionSave: function(e){
            // TODO: perform validations
            // not sure of the width and height in pixels, so we dodge the crop params. sucka
            // set UI state
            if(this.locked){
                return;
            }
            var scope = this;

            // deleted
            if(this.existing_image && this.parsedFile == null && this.dirty){

                app.confirm(
                    {
                        title: "Remove existing file?",
                        type: "error",
                        showCancelButton: true,
                        confirmButtonText: "Remove"
                    },
                    function(){
                        scope.lockInteraction();
                        $.ajax({
                            url: scope.API_ENDPOINT,
                            type: 'DELETE',
                            dataType: 'json',
                            contentType: 'application/json',
                            success: function(data){
                                scope.$el.removeAttr('data-existing-photo'); //hahahaha
                                $(document).trigger('onProfilePhotoState', 'delete');
                                scope.destroy();
                            },
                            error: function(error){
                                scope.displayError(error);
                            }
                        });
                    }
                );
            }else {
                // with image
                var payload = {
                    Crop: this.Crop
                }
                // set Crop back to model, for you know, kicks n stuff
                // TODO: REMOVE soon son
                try {
                    this.model.set('photo_thumb_crop_params',
                        this.Crop.Width + 'x' + this.Crop.Height + '+' + this.Crop.OriginX + '+' + this.Crop.OriginY);
                } catch (e) {
                    //pass
                }
                if(this.parsedFile != null){
                    payload['ProfilePhoto'] = this.parsedFile;
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
                        scope.$el.attr('data-existing-photo', true); //hahahah
                        $(document).trigger('onProfilePhotoState', 'update');
                        scope.destroy();
                    },
                    error: function(error){
                        scope.displayError(error);
                    }
                });
            }
            return false;
        },

        actionCancel: function(e){
            if(this.locked){
                return;
            }
            $(document).trigger('onProfilePhotoState', 'cancel');
            this.destroy();
        },

        destroy: function(){
            // wipe UI state
            this.actionRemove();
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