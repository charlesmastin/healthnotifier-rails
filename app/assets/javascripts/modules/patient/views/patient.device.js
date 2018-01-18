(function (Patient, Medication) {
    "use strict";
    Patient.Views.Device = Patient.Views.Collection.extend({
        // app.messages.WARNING_DELETE_DEVICE
        
        addOne: function(model) {
            
            var count = model.get('record_order') || this.count,
                validation = {
                    'health_event': {
                        required: true
                    },
                    'start_date': {
                        required: false,
                        naturalDate: 1
                    }
                };
            
            model.validation = validation;
            model.set({
                record_order: count
            });
            
            var hasRecords = 0;
            if (model.get('patient_id')) {
                if (count == 0) {
                    //##at should order this from the db source so all SYSTEM/NONE records are presented first
                    hasRecords = (model.get('health_event') == 'NONE') ? 0 : 1;
                    this.$("input[name=devices][value="+hasRecords+"]").attr('checked', 'checked');

                    if (!hasRecords) {
                        model.set('health_event','');
                        model.set('start_date',null);
                    }
                }
            }
            
            var view = new Patient.Views.CollectionItem({model: model, template: _.template($('#device-item').html()) });

            this.$('.entries .add').before(view.render().el);
            this.views.push(view);

            if (count > 0 || hasRecords) {
                this.$('.entries').toggle();
            }

            this.addAutocomplete(view.$('.device'), 'device');
            
            this.count++;
        },

        isValid: function() {
            if (this.$("input[name=devices]:checked").val() == 0 && this.views.length > 0) {
                // Set this patient explicitly to no conditions
                this.views[0].model.set('health_event','NONE');
                // remove the rest if present
                var i = 0;
                _.each(this.views, function(view) {
                    if (i++ > 0)
                        view.model.set('_destroy',true);
                });
                return true;
            }

            var validity = _.all(this.views, function(child) {
                child.model.validate();
                return child.model.isValid() === true;
            });
            return validity;
        }
    });
}(app.module('patient'), app.module('medication')));
