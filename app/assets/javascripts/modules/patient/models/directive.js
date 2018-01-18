(function (Patient) {
    "use strict";
    Patient.Models.Directive = Patient.Models.CollectionItem.extend({
        defaults: {
            value: '',
            patient_health_attribute_id: undefined,
        },

        idAttribute: 'patient_health_attribute_id',
        
        initialize: function () {
            _.bindAll(this, 'evictIllegals');           
            this.on('change', this.evictIllegals);
            this.evictIllegals();
            this.collection_name = 'patient_health_attributes';
        }
    });
    
    Patient.Collections.Directive = Patient.Collections.Collection.extend({
        model: Patient.Models.Directive,
        
        initialize: function (models, options) {
            Patient.Collections.Collection.prototype.initialize.apply(this, arguments);
            this.patient_id = options.patient_id;
            this.collection_name = 'patient_health_attributes';
        }
    });
}(app.module('patient')));
