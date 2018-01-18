(function (Patient) {
    "use strict";
    Patient.Views.Edit = Backbone.Abide.extend({
        events: {
        },

        // after all the things done be saved
        onDone: function(options){
            document.location.href = options.action;
        },
        
        initialize: function(options) {
            this.views = options.views;
            this.virgin = true;
            var self = this;


            // THIS IS GHETTO STRAPPED, because it's outside the scope of this root element
            $(document).off('click', '#action-transaction-save');
            $(document).on('click', '#action-transaction-save', function(e){
                e.stopImmediatePropagation();
                if($(e.currentTarget).hasClass('disabled')){
                    return false;
                }
                self.handleSubmit(e);
                return false;
            });

            $(document).off('onPatientChange');
            $(document).on('onPatientChange', function(e){
                e.stopImmediatePropagation();
                self.virgin = false; // it's really not accurate but it will have to do here
                $('#action-transaction-save').removeClass('disabled').css({'display': 'inline-block'}).removeAttr('disabled');
                $('#action-transaction-cancel').removeClass('disabled').css({'display': 'inline-block'});
            });


            // listen for changes on all the collections? if that's possible
            
            
            // bind self son

            self.timeSession = true;
            self.events = _.extend({}, self.events, self.unloadEvents);
            
            this.on('validating', function() {
                // $('.alert').html();
            }).on('validationFailed', function(e) {
                var $errors = $('.error-message:visible');
                if($errors.length > 0) {
                    // padding offset regardless son
                    var donglenuts = $errors.first().parent().find('input, select').first();
                    var anonHandlerTownUsa = function(){
                        setTimeout(function(){
                            try {
                                $(donglenuts[0]).focus();
                            } catch(e){
                            }
                        }, 100);
                    }

                    app.alert(app.messages.ERROR_INVALID_FORM_FIELDS, anonHandlerTownUsa, anonHandlerTownUsa);
                    var poff = 16*2; // 2rem;
                    $(window).stop().scrollTo($errors.first().parent().position().top - (app.calculateStuckTownOffset() + poff), 800);
                    // $(window).stop().scrollTo($errors.first().parent()[0], 800);
                } else {
                    //
                    app.alert(app.messages.ERROR_INVALID_FORM_FIELDS);
                    // window.app.showFlashMessage(app.messages.ERROR_INVALID_FORM_FIELDS, 'error', true);
                }
            }).on('done', function(e) {
                self.onDone(options);
            }).on('fail', function(jqXHR, textStatus, errorThrown) {
                if(jqXHR.status === 401) {
                    window.app.alert(app.messages.WARNING_SESSION_TIMEOUT_AND_REDIRECT);
                    setTimeout(function() {
                        self.renewSession();
                    }, 800);
                } else {
                    // grab the json of the response brosef.
                    var responseJson = JSON.parse(jqXHR.responseText);
                    if(responseJson.message != null){
                        window.app.alert('There was an error on our backend. \n' + responseJson.message);
                    }else {
                        // no worries dealing with the general mumbo jumbo of patient errors
                        // TODO: string format the patient errors son
                        window.app.alert(app.messages.ERROR_SUBMITTING_FORM);
                    }
                    
                }
            }).on('sessionExpired', self.renewSession).on('sessionTimeoutWarning', self.warnTimeout);
            
            //NOTE: Firefox 4+ doesn't show custom message. Could override with this bit of evil:
            //http://stackoverflow.com/questions/5398772/firefox-4-onbeforeunload-custom-message/9866486#9866486
            /*
            $(window).on('beforeunload', function(e) {
                if(self._dirty === true) {
                    if(e.originalEvent) {
                        e.returnValue = app.messages.WARNING_UNLOAD_UNSAVED_DATA;
                    }
                    return app.messages.WARNING_UNLOAD_UNSAVED_DATA;
                }
            });
            */
        },
        
        saveInputValue: function(e) {
            var target = e.target,
                type = target.type,
                id = target.id,
                //NOTE: Not very robust. Needs better betterness.
                value = (type != 'checkbox') ? target.value : target.checked;
            
            this.model.set(id, value);
        },
        
        handleSubmit: function(e) {
            e.preventDefault();
            this.submit(e, $('#action-transaction-save'));
        },

        promises: function() {
            var promises = [];
            // promises.push(this.model.save()); from edit-medical? hmmmm
            _.each(this.views, function(view) {
                //Plurals collection, needs mass saving
                if(view.saveCollection) {
                    promises.push(view.saveCollection());
                } else {
                    promises.push(view.model.save());
                }
            });
            return promises;
        },
        
        isValid: function() {
            var childFormsValid = true;
            _.each(this.views, function(view) {
                view.saveFormState();
                if(childFormsValid === true && view.isValid() === false) {
                    childFormsValid = false;
                } else{
                }
            });
            
            return childFormsValid;

            // from edit-medical, validation on the "patient.profile" for some silly reason

            // if(childFormsValid === false) {
            //     return false;
            // }

            // _.extend(this.model.validation, this.validationRules);
            
            // // TODO: re-eval logic flaw around changing genders and this validation
            
            // if(this.model.validation.maternity_state && $('[name=maternity_state]:checked').val() == "0") {
            //     delete this.model.validate.maternity_due_date;
            // }
            
            
            // this.model.validate();
            // return childFormsValid && this.model.isValid();


        }

    });
}(app.module('patient')));
