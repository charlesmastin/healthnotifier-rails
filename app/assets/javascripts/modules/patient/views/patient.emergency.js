(function (Patient, Medication) {
    "use strict";
    Patient.Views.Emergency = Patient.Views.Collection.extend({

        // app.messages.WARNING_DELETE_CONTACT
        // not true OO, so let's bring these back
        count: 0,
        views: [],
        
        addOne: function(model) {
            var count = model.get('record_order') || this.count,
                validation = {
                    'first_name': {
                        required: true
                    },
                    'last_name': {
                        required: true
                    },
                    'home_phone': {
                        required: true,
                        phone: 1
                    }
                };
            
            model.validation = validation;
            model.set({
                record_order: count
            });
            var view = new Patient.Views.CollectionItem({model: model, template: _.template($('#emergency-item').html())});

            this.$('.entries').append(view.render().el);
            this.views.push(view);
            
            view.model.on('validated', function(isValid, model, attrs) {
            });         
            
            var $contactRelationship = view.$('.contact_relationship'),
                contactRelationship = model.get('contact_relationship'),
                selectText = '&mdash;';
            
            //Make sure to set the custom select text after finding the proper option
            if(contactRelationship != undefined){
                $('option', $contactRelationship).each(function(index, option) {
                    if(option.value.toUpperCase() === contactRelationship.toUpperCase()) {
                        selectText = option.innerHTML;
                        $contactRelationship[0].selectedIndex = index;
                        return false;
                    }
                });
            }
            $('.custom-select span span', $contactRelationship.parent()).html(selectText);
            
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

        addInitial: function(model) {
            this.addOne(model);
        },

        preSave: function(req_object) {
            // TODO: map/reduce you dolt
            for(var i=0;i<req_object.patient_contacts.length;i++){
                //delete req_object.patient_contacts[i].home_phone_formatted;
            }
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
