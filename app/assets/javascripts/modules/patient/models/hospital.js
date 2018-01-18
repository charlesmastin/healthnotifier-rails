(function (Patient) {
    "use strict";
    Patient.Models.Hospital = Patient.Models.CollectionItem.extend({
        defaults: _.extend({
            name: '',
            medical_facility_type: 'HOSPITAL',
            phone: '',
            patient_medical_facility_id: undefined,
            address_line1: '',
            city: '',
            postal_code: '',
            state_province: '',
            country: 'US',
            privacy: 'public',
        }, Patient.Models.CollectionItem.prototype.defaults),

        idAttribute: 'patient_medical_facility_id',
        
        validation: {
            name: {
                required: true
            },
            phone: {
                required: false,
                phone: 1
            }
        },
        
        initialize: function () {
            _.bindAll(this, 'isEmpty');         
            this.on('change', this.evictIllegals);
            this.evictIllegals();
            this.collection_name = 'patient_medical_facilities';
        },
        
        isEmpty: function() {
            var self = this;
            return _.all(['name', 'phone', 'address_line1', 'city', 'state_province', 'postal_code'], function(item) {
                return !self.get(item);
            });
        }
    });
    
    Patient.Collections.Hospital = Patient.Collections.Collection.extend({
        model: Patient.Models.Hospital,
        
        initialize: function (models, options) {
            Patient.Collections.Collection.prototype.initialize.apply(this, arguments);
            this.patient_id = options.patient_id;
            this.collection_name = 'patient_medical_facilities';
        }
    });
}(app.module('patient')));
