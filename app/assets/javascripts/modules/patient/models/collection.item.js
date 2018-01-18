(function (Patient) {
    "use strict";
    Patient.Models.CollectionItem = Backbone.Model.extend({
        defaults: {
            patient_id: undefined,
            // patient_uuid: undefined,
            record_order: 0,
            privacy: 'provider',
            '_destroy': false
            // create_user: 0,
            // create_date: '',
        },
        
        initialize: function () {
            _.bindAll(this, 'evictIllegals', 'isNew', 'url', 'isEmpty');            
            this.on('change', this.evictIllegals);
            this.evictIllegals();
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
            
        }
    });
    
    
    Patient.Collections.Collection = Backbone.Collection.extend({
        model: Patient.Models.CollectionItem,
        
        initialize: function (models, options) {
            _.bindAll(this, 'url', 'save');
            this.patient_uuid = options.patient_uuid;
            this.collection_name = '';
        },
        
        url: function() {
            return '/api/v1/profiles/' + this.patient_uuid + '/' + this.collection_name;
        },

        save: function() {
            return this.map(function(model) {
                return model.save();
            });
        }
        
        //Do fun stuff here like custom comparator based on 'order'
    });
}(app.module('patient')));
