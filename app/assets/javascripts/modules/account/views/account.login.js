(function (Account) {
	"use strict";
	Account.Views.Login = Backbone.View.extend({
		defaults: {
		},

		events: {
			'submit form': 'handleSubmit',
			'click .login-signup': 'openSignupModal',
			'blur input': 'handleBlur'
		},

		initialize: function() {
			_.bindAll(this, 'render', 'reset', 'handleModelError', 'showError', 'handleBlur',
				'validateField', 'saveFormState', 'handleSubmit', 'openSignupModal');
			this.model.bind('error', this.handleModelError);
			this.model.fieldsToValidate = ['account_email', 'account_password'];
			this.render();
		},

		render: function() {
			this.reset();
			$('#login-email').focus();
		},

		reset: function() {
			var self = this;

			self.model.validation = {};
			self.$('input.error').removeClass('error');
			self.$('.error-message').hide();
			
			// self.$('form').get(0).reset();

			//Move off to avoid library unbinding overriding this
			setTimeout(function () {
				self.$el.on('reveal:close', function() {
					self.reset();
				});
			}, 100);
		},

		handleModelError: function(view, errorMessages, options) {
			var self = this;
			_.each(errorMessages, function(field) {
				self.showError(field);
			});
		},

		showError: function(el) {
			var $el = $(el),
				errorMessage = $el.parent().find('.error-message');

			$el.addClass('error');
			if(errorMessage[0]) {
				errorMessage.addClass('present-error-message').show();
			}
		},

		handleBlur: function(e) {
			this.validateField(e.target);
		},

		validateField: function(el) {
			var $el = $(el);
			$el.removeClass('error');
			$el.parent().find('.error-message').removeClass('present-error-message').hide();

			var id = el.id,
				value = el.value;

			//NOTE: This very well may suck. Look at all this tight coupling…
			var dataField = $(el).data('field');
			if(dataField)
				this.model.attributes[dataField] = value;


			var dataValidation = $(el).data('validation'),
				validationType = (dataValidation) ? dataValidation : false;
			if(validationType && !this.model[validationType](value)) {
				this.showError(el);
			}
		},

		saveFormState: function() {
			this.model.set({
				'account_email': $('#login-email').val(),
				'account_password': $('#login-password').val()
			});
		},

		handleSubmit: function(e) {
			var self = this;
			$('.error-message').hide();
			this.saveFormState();
			var validationErrors = this.model.validationErrors;
			if(validationErrors.length > 0) {
				e.preventDefault();
				_.each(this.$el.find('input:visible'), function(el) {
					self.validateField(el);
				});
				return false;
			}

			this.$('[type=submit]').removeClass('medium').text('Logging in...').attr('disabled', true);
		},

		openSignupModal: function(e) {
			e.preventDefault();
			$('#login-modal').trigger('reveal:close');
			setTimeout(function() {
				$('#signup-label a').click();
			}, 500);
		}
	});
}(app.module('account')));
