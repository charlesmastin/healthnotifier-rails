(function (Patient) {
    "use strict";
    Patient.Models.Medication = Patient.Models.CollectionItem.extend(
    {
        defaults : _.extend({
            icd9_code: '',
            icd10_code: '',
            imo_code: '',
            therapy: '',
            therapy_strength_form: '',
            therapy_frequency: '',
            therapy_quantity: '',
            patient_therapy_id: undefined,
        }, Patient.Models.CollectionItem.prototype.defaults),

        idAttribute: 'patient_therapy_id',

        initialize: function () {
            _.bindAll(this, 'isEmpty');
            this.on('change', this.evictIllegals);
            this.evictIllegals();
            this.collection_name = 'patient_therapies';
        },

        isEmpty: function() {
            var self = this;
            return _.all(['therapy', 'therapy_strength_form', 'therapy_frequency', 'therapy_quantity'], function(item) {
                return !self.get(item);
            });
        }
    });

    Patient.Collections.Medication = Patient.Collections.Collection.extend({
        model: Patient.Models.Medication,

        initialize: function (models, options) {
            Patient.Collections.Collection.prototype.initialize.apply(this, arguments);
            this.patient_id = options.patient_id;
            this.collection_name = 'patient_therapies';
        }
    });
}(app.module('patient')));
