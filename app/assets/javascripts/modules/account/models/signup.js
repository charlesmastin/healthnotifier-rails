(function (Account) {
    "use strict";
    Account.SignupModel = Backbone.Model.extend({
        defaults: {
            'email': '',
            'password': '',
            'first_name': '',
            'last_name': '',
            'dob': '',
            'accept_terms': '',
            //'mobile_phone_country': '+1',// meh meh meh
            'mobile_phone': ''
        },

        validation: {
            'email': {
                required: true,
                pattern: 'email'
            },
            'password': {
                password: 1
            },
            'dob': {
                required: true,
                usDate: 1
            },
            'first_name': {
                required: true
            },
            'last_name': {
                required: true
            },
            'accept_terms': {
                acceptance: true
            }

            // that phone number though
        },

        initialize: function () {
            
        }
    });
}(app.module('account')));
