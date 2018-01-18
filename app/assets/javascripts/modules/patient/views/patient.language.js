(function (Patient, Medication) {
    "use strict";
    Patient.Views.Language = Patient.Views.Collection.extend({
        // app.messages.WARNING_DELETE_LANGUAGE
        count: 0,
        views: [],

        addInitial: function(model) {
            this.addOne(model);
        },

        addOne: function(model) {
            var count = model.get('record_order') || this.count,
                validation = {
                    language_code: {
                        required: true
                    },
                    language_proficiency: {
                        required: true
                    }
                };
            
            model.validation = validation;
            model.set({
                record_order: count
            });
            
            var view = new Patient.Views.CollectionItem({model: model, template: _.template($('#language-item').html())});
            this.$('.entries').append(view.render().el);
            this.views.push(view);
            
            var $languageCode = view.$('.language_code'),
                languageCode = model.get('language_code'),
                $proficiency = view.$('.language_proficiency'),
                proficiency = model.get('language_proficiency'),
                codeSelectText = '&mdash;',
                proficiencySelectText = '&mdash;';
            
            //Make sure to set the custom select text after finding the proper option
            if (languageCode) {
                $('option', $languageCode).each(function(index, option) {
                    if(option.value === languageCode) {
                        codeSelectText = option.innerHTML;
                        $languageCode[0].selectedIndex = index;
                        return false;
                    }
                });
                if(proficiency != undefined){
                    $('option', $proficiency).each(function(index, option) {
                        if(option.value.toUpperCase() === proficiency.toUpperCase()) {
                            proficiencySelectText = option.innerHTML;
                            $proficiency[0].selectedIndex = index;
                            return false;
                        }
                    });
                }
            } else {
                $('option', $proficiency).each(function(index, option) {
                    if(option.value === 'en') {
                        proficiencySelectText = option.innerHTML;
                        model.set('language_proficiency', option.value);
                        $proficiency[0].selectedIndex = index;
                        return false;
                    }
                });
            }
            $('.custom-select span span', $languageCode.parent()).html(codeSelectText);
            $('.custom-select span span', $proficiency.parent()).html(proficiencySelectText);
            

            view.remove = function () {
                view.$el.remove();
                view.model.set('_destroy', true);
                this.model.validation = {};
                this.validationRules = {};
                //HACK: Yes, this stinks.
                this.model.validate = function() { return true; };
                this.model.isValid = function() {return true; };
            };

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
        }
    });
}(app.module('patient'), app.module('medication')));
