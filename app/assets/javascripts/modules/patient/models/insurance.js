(function (Patient) {
    "use strict";
    Patient.Models.Insurance = Patient.Models.CollectionItem.extend({
        defaults: _.extend({
            organization_name: '',
            policy_code: '',
            phone: '',
            patient_insurance_id: undefined,
            group_code: '',
            policyholder_first_name: '',
            policyholder_last_name: '',
        }, Patient.Models.CollectionItem.prototype.defaults),

        idAttribute: 'patient_insurance_id',
        
        validation: {
            organization_name: {
                required: true
            }
        },
        
        initialize: function () {
            _.bindAll(this, 'isEmpty');         
            this.on('change', this.evictIllegals);
            this.evictIllegals();
            this.collection_name = 'patient_insurances';
        },
        
        isEmpty: function() {
            var self = this;
            return _.all(['organization_name', 'phone', 'policy_code', 'group_code', 'policyholder_first_name', 'policyholder_last_name'], function(item) {
                return !self.get(item);
            });
        }
    });
    
    Patient.Collections.Insurance = Patient.Collections.Collection.extend({
        model: Patient.Models.Insurance,
        
        initialize: function (models, options) {
            Patient.Collections.Collection.prototype.initialize.apply(this, arguments);
            this.patient_id = options.patient_id;
            this.collection_name = 'patient_insurances';
        }
    });
}(app.module('patient')));
