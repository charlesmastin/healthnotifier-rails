(function (Patient) {
    "use strict";
    Patient.Models.Emergency = Patient.Models.CollectionItem.extend({
        defaults: _.extend({
            first_name: '',
            last_name: '',
            email: '',
            home_phone: '',
            contact_relationship: '',
            patient_contact_id: undefined,
            notification_postscan: true,
            power_of_attorney: false,
            next_of_kin: false,
            privacy: 'public',
            'list_advise_send_date': undefined
        }, Patient.Models.CollectionItem.prototype.defaults),

        idAttribute: 'patient_contact_id',
        
        validation: {
            first_name: {
                required: true
            },
            last_name: {
                required: true
            },
            home_phone: {
                required: true,
                phone: 1
            },
            email: {
                required: false,
                pattern: 'email'
            }
        },
        
        initialize: function () {
            _.bindAll(this, 'isEmpty');            
            this.on('change', this.evictIllegals);
            this.evictIllegals();
            this.collection_name = 'patient_contacts';
        },
        
        isEmpty: function() {
            var self = this;
            return _.all(['first_name', 'last_name'], function(item) {
                return !self.get(item);
            });
        }
    });
    
    Patient.Collections.Emergency = Patient.Collections.Collection.extend({
        model: Patient.Models.Emergency,
        
        initialize: function (models, options) {
            Patient.Collections.Collection.prototype.initialize.apply(this, arguments);
            this.patient_id = options.patient_id;
            this.collection_name = 'patient_contacts';
        }
    });
}(app.module('patient')));
