(function (Patient) {
    "use strict";
    Patient.Models.Residence = Patient.Models.CollectionItem.extend(
    {
        defaults: _.extend({
            address_line1: '',
            address_line2: '',
            address_line3: '',
            city: '',
            mailing_address: false,
            patient_residence_id: undefined,
            postal_code: '',
            residence_type: '', // ahh yea son
            state_province: '',
            country: 'US',
            lifesquare_location_type: undefined, // this is a bs placeholder for the raw int, because well rails
            lifesquare_location_other: undefined,
            '_validated': false,
            '_validation_override': false,
        }, Patient.Models.CollectionItem.prototype.defaults),

        idAttribute: 'patient_residence_id',
        
        validation: {
            address_line_1: {
                required: true
            },
            city: {
                required: true
            },
            state_province: {
                required: true
            },
            country: {
                required: true
            },
            postal_code: {
                required: true
            },
            // this could be the flub
            residence_type: {
                required: true
            },
            // this could be the other flub?
            lifesquare_location_type: {
                required: true
            }
        },
        
        mutators: {
            /*
            state_province: {
                get: function() {
                    return this.state_province;
                },
                set: function(key, value, options, set) {
                    if(/^[a-z]{2}$/i.test(value)) {
                        set('state_province', value.toUpperCase(), options);
                    } else {
                        set('state_province', '', options);
                    }
                }
            }
            */
        },
        
        initialize: function () {
            _.bindAll(this, 'evictIllegals', 'isNew', 'url', 'isEmpty');
            this.on('change', this.evictIllegals);
            this.evictIllegals();
            this.collection_name = 'patient_residences';
        },

        //Removes values that shouldn't be sent back during a sync
        evictIllegals: function() {
            var self = this,
                allowed = _.keys(this.defaults);

            _.each(self.attributes, function(value, key) {
                if(!!~allowed.indexOf(key) === false) {
                    delete self.attributes[key];
                }
            });
        },
        
        isNew: function() {
            return this.id ? false : true;
        },
        
        url: function() {
            return '/api/v1/profiles/' + this.get('patient_uuid') + '/' + this.collection_name;
        },
        
        isEmpty: function() {
            var self = this;
            return _.all(['address_line_1', 'address_line_2', 'address_line_3', 'city', 'state_province', 'postal_code'], function(item) {
                return !self.get(item);
            });
        }
    });
    
    Patient.Collections.Residence = Patient.Collections.Collection.extend({
        model: Patient.Models.Residence,
        
        initialize: function (models, options) {
            _.bindAll(this, 'url', 'save');
            Patient.Collections.Collection.prototype.initialize.apply(this, arguments);
            this.patient_uuid = options.patient_uuid;
            this.collection_name = 'patient_residences';
        },
        
        url: function() {
            return '/api/v1/profiles/' + this.patient_uuid + '/' + this.collection_name;
        },

        save: function() {
            return this.map(function(model) {
                return model.save();
            });
        }
    });
}(app.module('patient')));
