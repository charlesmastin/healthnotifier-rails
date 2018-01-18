(function (Patient) {
    "use strict";
    Patient.Views.EditMedical = Patient.Views.Edit.extend({
        events: _.extend({
            'click .presence': 'recordPresence' // these are for the positive negatives and are currently not in use
        }, Patient.Views.Edit.prototype.events),

        initialize: function(options) {
            // do everything in the "super" first
            Patient.Views.Edit.prototype.initialize.apply(this, arguments);
            var self = this;

            _.bindAll(this, 'saveCachedRadioSelections', 'saveInputValue',
                'handleSubmit', 'promises', 'isValid' );

            self.validationRules = {
                /*
                medication_presence: {
                    required: true
                },
                allergy_presence: {
                    required: true
                },
                condition_presence: {
                    required: true
                },
                procedure_presence: {
                    required: true
                },
                directive_presence: {
                    required: true
                },
                immunization_presence: {
                    required: true
                }
                */
            };
            // _.extend(self.validationRules, self.model.validation);
            self.model.validation = {};

            // add if the gender is in the nebulous category, same logic in order to show it in the first place
            var g = self.model.get('gender');
            if(g == null || g == 'female' || g == ''){
                self.validationRules.maternity_state = {
                    required: true
                }
            }

            Backbone.Validation.bind(this, {
                forceUpdate: true,
                selector: 'name',
                valid: function (view, attr) {
                    var field = $('[name="' + attr + '"]');
                    field.removeClass('error');
                    $("[data-for='" + attr + "']").hide();
                },
                invalid: function(view, attr, error) {
                    console.log('some invalid stuffs', view, attr, error);
                    var field = $('[name="' + attr + '"]');
                    field.addClass('error');
                    $("[data-for='" + attr + "']").show();
                }
            });

            this.model.on('validated', function(isValid, model, attrs) {
                if (isValid) {
                    self.$('.error-message').hide();
                }
            });

            self.saveCachedRadioSelections.call(this);
        },

        saveCachedRadioSelections: function() {
            var self = this;
            _.each(self.validationRules, function(rule, key) {
                var $checkedRadio = $('[name=' + key + ']:checked');
                if(self.model.get(key) === null && $checkedRadio.length === 1) {
                    self.model.set(key, $checkedRadio.val());
                }
            });
        },

        // these are for the positive negatives and are currently not in use
        recordPresence: function(e) {
            // e.preventDefault();

            //HACK: This should be mapped better
            var key = e.target.name,
                val = ~~e.target.value,
                map = {
                    medication_presence: 'medication_presence',
                    allergy_presence: 'allergy_presence',
                    condition_presence: 'condition_presence',
                    directive_presence: 'directive_presence',
                    procedure_presence: 'procedure_presence',
                    maternity_state: 'maternity_state',
                    immunization_presence: 'immunization_presence'
                };

            if(map[key]) {
                this.model.validation[key] = {
                    required: true
                }
                this.model.set(map[key], val);
            }
        },

        handleSubmit: function(e) {
            e.preventDefault();
            var self = this;
            if(!self.model.get('confirmed') && self.virgin){
                // callback on your steeze for app.confirm son
                app.confirm({
                    title: "Proceed with no medical history?",
                    text: "You may enter it later and update at any time but we recommend adding it now.",
                    type: "info",
                    showCancelButton: true,
                    allowOutsideClick: false,
                    confirmButtonText: "Proceed"
                    },
                    function(){
                        // _presence bits, meh meh meh

                        // until we offer up each of these again
                        // can we pass along a single "skip" param that goes in a session or something
                        // we can use this along with any actual data to check state

                        self.submit(e, $('#action-transaction-save'));
                    }
                );
            }else {
                self.submit(e, $('#action-transaction-save'));
            }
        }

    })
})(app.module('patient'));
