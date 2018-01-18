(function (Patient) {
    "use strict";
    Patient.Models.Allergy = Patient.Models.CollectionItem.extend({

        defaults : _.extend({
            allergen: '',
            imo_code: '',
            icd9_code: '',
            icd10_code: '',
            reaction: '',
            patient_allergy_id: undefined,
            privacy: 'public',
        }, Patient.Models.CollectionItem.prototype.defaults),

        idAttribute: 'patient_allery_id',

        initialize: function () {
            _.bindAll(this, 'isEmpty');
            this.on('change', this.evictIllegals);
            this.evictIllegals();
            this.collection_name = 'patient_allergies';
        },

        isEmpty: function() {
            var self = this;
            return _.all(['allergen', 'reaction'], function(item) {
                return !self.get(item);
            });
        }
    });

    Patient.Collections.Allergy = Patient.Collections.Collection.extend({
        model: Patient.Models.Allergy,

        initialize: function (models, options) {
            Patient.Collections.Collection.prototype.initialize.apply(this, arguments);
            this.patient_id = options.patient_id;
            this.collection_name = 'patient_allergies';
        }
    });
}(app.module('patient')));
