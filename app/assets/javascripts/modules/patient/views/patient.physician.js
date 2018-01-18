(function (Patient, Medication) {
    "use strict";
    Patient.Views.Physician = Patient.Views.Collection.extend({
        
        // app.messages.WARNING_DELETE_PHYSICIAN
        // not true OO, so let's bring these back
        count: 0,
        views: [],

        events : _.extend({
            'change select[name="country"]': 'handleCountryChange',
            // TODO: US address validator mixin events
        }, Patient.Views.Collection.prototype.events),

        handleCountryChange: function(event) {
            // TODO: handle actual usage focus, not really a big deal son
            if($(event.currentTarget).val() == 'US'){
                $(event.currentTarget).parents('div.item').find('select.state_province').show();
                $(event.currentTarget).parents('div.item').find('input.state_province').hide();
            }else{
                $(event.currentTarget).parents('div.item').find('select.state_province').hide();
                $(event.currentTarget).parents('div.item').find('input.state_province').show();
            }
        },

        addOne: function(model) {
            
            var count = model.get('record_order') || this.count,
                validation = {
                    'last_name': {
                        required: true
                    },
                    'phone1': {
                        phone: 1,
                        required: false
                    }
                };
            
            model.validation = validation;
            model.set({
                record_order: count
            });
            var view = new Patient.Views.CollectionItem({model: model, template: _.template($('#physician-item').html())});
            
            this.$('.entries').append(view.render().el);
            this.views.push(view);
            view.model.on('validated', function(isValid, model, attrs) {
            });

            // lul
            view.$('.care_provider_class').val(model.get('care_provider_class'));

            // set country / state stuffs
            view.$('.country').val(model.get('country'));
            view.$('.state_province').val(model.get('state_province'));
            view.$('.country').trigger('change');// ghetto workaround to initial view state

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

            view.$('.state_province').val(model.get('state_province'));

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
