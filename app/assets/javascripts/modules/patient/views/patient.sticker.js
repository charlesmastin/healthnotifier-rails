(function(Patient) {
    "use strict";
    Patient.Views.Sticker = Backbone.View.extend({
        events: {
            'click .enter-code': 'showForm',
            'click .cancel-code': 'hideForm',
            'focus .lifesquare-uid': 'focusLifesquareCode',
            'keydown .lifesquare-uid': 'keyDownLifesquareCode',
            'keyup .lifesquare-uid': 'keyUpLifesquareCode',
            'blur .lifesquare-uid': 'blurLifesquareCode',
        },
        
        initialize: function(options) {
            this.options = options;
            _.bindAll(this, 'showForm', 'hideForm', 'keyUpLifesquareCode', 'keyDownLifesquareCode', 'focusLifesquareCode', 'blurLifesquareCode');
            
            var self = this;
            
            self.index = this.options.index;
            self.$codeContainer = self.$('.account-code');
            self.$buttonContainer = self.$('.sticker-options');
            self.$formContainer = self.$('.sticker-code');
            
            if(self.$('.lifesquare-code').html() !== '') {
                self.$codeContainer.show();
                self.$buttonContainer.hide();
                self.$formContainer.hide();
            }
            
            // self.model.set('patient_id', self.$('[name^=patient_id]').val());
            
            Backbone.Validation.bind(this, {
                forceUpdate: true,
                selector: 'name',
                valid: function (view, attr) {
                    var field = view.$('[name=' + attr + ']');
                    field.removeClass('error');
                    self.$("[data-for='" + attr + "']").hide();
                },
                invalid: function(view, attr, error) {
                    var field = view.$('[name=' + attr + ']');
                    field.addClass('error');
                    self.$("[data-for='" + attr + "']").show();
                }
            });
        },

        updateState: function(state) {
            this.$('.state-valid').hide();
            this.$('.state-invalid').hide();
            this.$('.state-loading').hide();
            if(state != undefined){
                this.$('.state-'+state).css({'display': 'inline-block'});
            }
        },
        
        showForm: function(e) {
            // e.preventDefault();
            this.$buttonContainer.hide();
            this.$formContainer.show();
            this.$formContainer.find('input').focus();
            // we should always start on a clear form here… so it should be a no brainer
            this.updateState('loading');
        },
        
        hideForm: function(e) {
            // simplify things, empty the lifesquare
            this.model.set('lifesquare_uid', '');
            this.model.set('lifesquare_uid_formatted', '');
            e.preventDefault();
            this.$buttonContainer.show();
            this.$formContainer.hide();
            this.$('.need-code').attr('checked', true);
            this.updateState();
            $(document).trigger('onAssignValidateLifesquares');

        },

        focusLifesquareCode: function(e){
            this.updateState('loading');
        },

        keyDownLifesquareCode: function(e){
            // only permit permissable things
            if(e.which == 32){
                e.preventDefault();
                return;
            }
        },
        
        keyUpLifesquareCode: function(e) {
            // TODO: handle previous select UX state, LOL son, result would be, is selected
            if(window.getSelection().toString().length){
                e.preventDefault();
                return;
            }
            var uid = e.target.value.replace(/[^a-z0-9]/gi, '').toUpperCase(),
                splitUid = [];
            
            for(var i=0; i<3; i++) {
                var sub = uid.substring(i * 3, (i+1) * 3);
                if(sub.length > 0) {
                    splitUid.push(sub);
                }
            }
            e.target.value = splitUid.join(' ');
            if(e.target.value.split(' ').join('').length != 9){
                // clear our attribtue for previous value
                $(e.target).removeAttr('data-previous-state');
            } else {
                // attempt to read
                var existing = $(e.target).attr('data-previous-state');
                // value check the current and previous, in case we used the selection to replace something
                if((existing != undefined && uid != existing) || existing == undefined) {
                    $(e.target).attr('data-previous-state', uid);
                    $(e.target).blur();
                    // $(document).trigger('onAssignValidateLifesquares');
                }
            }
        },
        
        blurLifesquareCode: function(e) {
            // if we have a different value than our last confirmed value, me
            
            // if we're not in the lock mode of performing a validation
            // 

            // check values
            // this is ghetto town son
            // this is on blur, but we might have "cancelled the entry" so we don't need to validate as a square… or do we
            // the close button will have already trigger a local event to bubble, this would be double hit chen
            this.model.set('lifesquare_uid_formatted', e.target.value);
            var scope = this;

            // TODO: optimization only trigger if changed???? else... use previous validation
            $(document).trigger('onAssignValidateLifesquares');
            /*
            // this is an extra cycle, but it ensures it happens
            setTimeout(function(){
                var c = scope.model.attributes.lifesquare_uid_formatted.split(' ').join('');
                if(c.length == 9){
                    // $(document).trigger('onAssignValidateLifesquares');
                } else {
                    scope.updateState('invalid');// this is a pre-server invalidation
                }
            }, 25);
            */
        }
    });
})(app.module('patient'));
