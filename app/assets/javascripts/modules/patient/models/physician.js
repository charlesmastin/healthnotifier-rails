(function (Patient) {
    "use strict";
    Patient.Models.Physician = Patient.Models.CollectionItem.extend({
        defaults: _.extend({
            first_name: '',
            last_name: '',
            care_provider_class: '',
            phone1: '',
            patient_care_provider_id: undefined,
            address_line1: '',
            address_line2: '',
            city: '',
            postal_code: '',
            email: '',
            state_province: '',
            country: 'US',
            medical_facility_name: ''
        }, Patient.Models.CollectionItem.prototype.defaults),

        idAttribute: 'patient_care_provider_id',
        
        validation: {
            last_name: {
                required: true
            },
            phone1: {
                required: false,
                phone: 1
            }
        },
        
        initialize: function () {
            _.bindAll(this, 'isEmpty');         
            this.on('change', this.evictIllegals);
            this.evictIllegals();
            this.collection_name = 'patient_care_providers';
        },
        
        isEmpty: function() {
            var self = this;
            return _.all(['first_name', 'last_name', 'phone1', 'medical_facility_name', 'address_line1', 'address_line2', 'city', 'state_province', 'postal_code', ], function(item) {
                return !self.get(item);
            });
        }
    });
    
    Patient.Collections.Physician = Patient.Collections.Collection.extend({
        model: Patient.Models.Physician,
        
        initialize: function (models, options) {
            Patient.Collections.Collection.prototype.initialize.apply(this, arguments);
            this.patient_id = options.patient_id;
            this.collection_name = 'patient_care_providers';
        }
    });
}(app.module('patient')));
