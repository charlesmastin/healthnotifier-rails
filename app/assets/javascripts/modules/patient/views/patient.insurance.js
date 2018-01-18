(function (Patient, Medication) {
    "use strict";
    Patient.Views.Insurance = Patient.Views.Collection.extend({
        // app.messages.WARNING_DELETE_INSURANCE
        // not true OO, so let's bring these back
        count: 0,
        views: [],

        addOne: function(model) {
            
            var count = model.get('record_order') || this.count,
                validation = {
                    'organization_name': {
                        required: true
                    },
                    'phone': {
                        phone: 1,
                        required: false
                    }
                };
            
            model.validation = validation;
            model.set({
                record_order: count
            });
            var view = new Patient.Views.CollectionItem({model: model, template: _.template($('#insurance-item').html())});
            this.$('.entries').append(view.render().el);
            this.views.push(view);
            view.model.on('validated', function(isValid, model, attrs) {
            });

            // FIXME: hmm, seems really labor intensive to setup property - UI binding
            // jquery supports more straightforward assignment as well, probably should simplify
            var $privacy = view.$('.privacy'),
                privacy = model.get('privacy'),
                selectText = '&mdash;'; // should not have a default value here
            
            //Make sure to set the custom select text after finding the proper option
            $('option', $privacy).each(function(index, option) {
                if(option.value === privacy) {
                    selectText = option.innerHTML;
                    $privacy[0].selectedIndex = index;
                    return false;
                }
            });


            // handle the custom selection action, if relevant
            $('.custom-select span span', $privacy.parent()).html(selectText);

            if(model.isNew()){
                this.collection.add(model);
            }
            
            this.count++;
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
        },

        preSave: function(req_object) {
            return req_object;
        }
    });
}(app.module('patient'), app.module('medication')));
