(function (Account) {
	"use strict";
	Account.Model = Backbone.Model.extend({
		defaults: {
			passwordMinLength: 8,
			account_email: '',
			account_password: '',
			postal_code: '',
			terms: ''
		},
		errors: {
			BAD_EMAIL: 'account_email',
			EMAIL_MISMATCH: 'email_confirmation',
			BAD_PASSWORD: 'account_password',
			PASSWORD_MISMATCH: 'password_confirmation',
			BAD_POSTAL_CODE: 'postal_code',
			NO_TERMS: 'terms'
		},
		fieldsToValidate: [
			'account_email',
			'email_confirmation',
			'account_password',
			'password_confirmation',
			'postal_code',
			'terms'
		],

		initialize: function () {
			console.log('hello account');
			_.bindAll(this, 'validate', 'matchingEmails', 'validPassword', 'matchingPasswords', 'validPostalCode');
			this.validationErrors = [];
		},

		validate: function(attrs) {
			var errors = [],
				email = (typeof attrs.account_email !== 'undefined') ? attrs.account_email : '',
				confirm_email = (typeof attrs.email_confirmation !== 'undefined') ? attrs.email_confirmation : '',
				password = (typeof attrs.account_password !== 'undefined') ? attrs.account_password : '',
				confirm_password = (typeof attrs.password_confirmation !== 'undefined') ? attrs.password_confirmation : '',
				postal_code = (typeof attrs.postal_code !== 'undefined') ? attrs.postal_code : '',
				terms = (typeof attrs.terms !== 'undefined') ? attrs.terms : '';

			if(!!~this.fieldsToValidate.indexOf('account_email') && !this.validEmail(email)) {
				errors.push(new Error(this.errors.BAD_EMAIL));
			}

			if(!!~this.fieldsToValidate.indexOf('email_confirmation') && confirm_email !== email) {
				errors.push(new Error(this.errors.EMAIL_MISMATCH));
			}

			if(!!~this.fieldsToValidate.indexOf('account_password') && !this.validPassword(password)) {
				errors.push(new Error(this.errors.BAD_PASSWORD));
			}

			if(!!~this.fieldsToValidate.indexOf('password_confirmation') && confirm_email !== email) {
				errors.push(new Error(this.errors.PASSWORD_MISMATCH));
			}

			if(!!~this.fieldsToValidate.indexOf('postal_code') && !this.validPostalCode(postal_code)) {
				errors.push(new Error(this.errors.BAD_POSTAL_CODE));
			}

			if(!!~this.fieldsToValidate.indexOf('terms') && !this.termsAccepted(terms)) {
				errors.push(new Error(this.errors.NO_TERMS));
			}

			this.validationErrors = errors;
			return errors;
		},

		validEmail: function(email) {
			return !!email.match(/[\w\d]+@[\w\d]+.[\w\d]{2,4}/);
		},

		matchingEmails: function(confirmingEmail) {
			return this.attributes.account_email === confirmingEmail;
		},

		validPassword: function(password) {
			return password.length >= this.defaults.passwordMinLength && !!password.match(/[a-z]/) && (!!password.match(/[\d]/) || !!password.match(/[^\w\d]/));
		},

		matchingPasswords: function(confirmingPassword) {
			return this.attributes.account_password === confirmingPassword;
		},

		//NOTE: Will only work with American postal codes
		validPostalCode: function(postalCode) {
			return !!postalCode.match(/^([\d]{5})(?:-[\d]{4})?$/);
		},

		termsAccepted: function(terms) {
			return terms;
		}
	});
}(app.module('account')));
