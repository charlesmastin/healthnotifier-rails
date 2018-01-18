(function (Account) {
    "use strict";
    Account.SignupEnterpriseModel = Backbone.Model.extend({
        defaults: {
            'email': '',
            'password': '',
            'first_name': '',
            'last_name': '',
            'organization_name': '',
            'accept_terms': '',
            'business_phone': ''
        },

        validation: {
            'email': {
                required: true,
                pattern: 'email'
            },
            'password': {
                password: 1
            },
            'organization_name': {
                required: true
            },
            'mobile_phone': {
                required: true,
                phone: 1
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
        },

        initialize: function () {
            
        }
    });
}(app.module('account')));
