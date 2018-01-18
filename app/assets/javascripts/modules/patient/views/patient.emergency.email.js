(function (Patient, Medication) {
    "use strict";
    Patient.Views.EmergencyEmail = Patient.Views.Collection.extend({

        postInitialize: function() {
            /*
            if(this.count===0) {
                this.$('.content').append('<p class="no_entries emergency">No emergency contacts listed. You can <a href="/profile/edit-contacts">add some now</a> if you want.</p>');
            }
            */
        },

        count: 0,
        views: [],
        
        addOne: function(model) {
            var count = model.get('record_order') || this.count,
                validation = {
                    'email': {
                        pattern: 'email',
                        required: false
                    }
                };
            
            model.validation = validation;
            model.set({
                record_order: count
            });

            var template = model.get('list_advise_send_date') ? $('#list-item').html() : $('#email-item').html(),
                view = new Patient.Views.CollectionItem({
                    model: model,
                    template: _.template(template)
                });

            view.model.on('change:email', function() {
                view.$('.fine-detail').hide();
                view.model.set({
                    'list_advise_send_date': undefined
                });
            });
            view.confirmClear = this.confirmClear;

            this.$('.entries').append(view.render().el);

            this.views.push(view);
            
            this.count++;
        },

        preSave: function(req_object) {
            return req_object;
        },
        
        isValid: function() {
            var childFormsValid = true;
            _.each(this.views, function(child) {
                child.model.validate();
                if(childFormsValid === true && child.model.isValid() === false) {
                    childFormsValid = false;
                }
            });
            
            return childFormsValid;
        }
    });
}(app.module('patient'), app.module('medication')));
