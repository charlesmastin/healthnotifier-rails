(function (Patient) {
    "use strict";
    Patient.Models.Pharmacy = Patient.Models.CollectionItem.extend({
        defaults: _.extend({
            name: '',
            phone: '',
            patient_pharmacy_id: undefined,
            address_line1: '',
            city: '',
            postal_code: '',
            state_province: '',
            country: 'US'
        }, Patient.Models.CollectionItem.prototype.defaults),

        idAttribute: 'patient_pharmacy_id',
        
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
            this.collection_name = 'patient_pharmacies';
        },
        
        isEmpty: function() {
            var self = this;
            return _.all(['name', 'phone', 'address_line1', 'city', 'state_province', 'postal_code'], function(item) {
                return !self.get(item);
            });
        }
    });
    
    Patient.Collections.Pharmacy = Patient.Collections.Collection.extend({
        model: Patient.Models.Pharmacy,
        
        initialize: function (models, options) {
            Patient.Collections.Collection.prototype.initialize.apply(this, arguments);
            this.patient_id = options.patient_id;
            this.collection_name = 'patient_pharmacies';
        }
    });
}(app.module('patient')));
