(function (Patient) {
    "use strict";

    Patient.Models.Sticker = Backbone.Model.extend({
        defaults: {
            patient_uuid: null,
            lifesquare_uid: '',
            lifesquare_uid_formatted: ''
        },
        
        validation: {
            'lifesquare_uid_formatted': {
                required: true
                // pattern: 'lifesquareCode'
            }
        },
        
        mutators: {
            'lifesquare_uid_formatted': {
                get: function() {
                    return this.lifesquare_uid;
                },
                
                set: function(key, value, options, set) {
                    set('lifesquare_uid_formatted', value, options);
                    set('lifesquare_uid', value.replace(/[^a-z0-9]/gi, '').toUpperCase(), options);
                }
            }
        }
    });
    
    Patient.Collections.Sticker = Backbone.Collection.extend({
        model: Patient.Models.Sticker,
        
        collection_name: 'stickers',
    });

    
}(app.module('patient')));
