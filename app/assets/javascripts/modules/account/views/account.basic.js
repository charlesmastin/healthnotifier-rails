(function (Account) {
	"use strict";
	Account.Views.Basic = Backbone.View.extend({
		defaults: {
		},

		events: {
			'click #submit-button': 'handleSubmit',
			// 'blur input': 'handleBlur'
			'click .race': 'manageEthnicityOptions',
			'click #mailing-same': 'sameShippingAddress',
			//'change #thumbnail': 'showThumbnailFilename',
			//'click #thumbnail-reset': 'resetThumbnail'
		},

		initialize: function() {
			_.bindAll(this, 'handleModelError', 'showError', 'handleBlur', 'saveFormState', 'handleSubmit',
				'manageEthnicityOptions', 'sameShippingAddress');//, 'showThumbnailFilename', 'resetThumbnail');

			this.model.fieldsToValidate = [];
			this.render();
		},

		render: function() {
		},

		handleModelError: function(view, errorMessages, options) {
			var self = this;
			_.each(errorMessages, function(field) {
				self.showError(field);
			});
		},

		showError: function(field) {
			var self = this;
			var errorMessage = $('#' + field).parent().find('.error-message');
			if(errorMessage[0]) {
				errorMessage.addClass('present-error-message').show();
			}
		},

		handleBlur: function(e) {
			$('#' + e.target.id).parent().find('.error-message').removeClass('present-error-message').hide();
			//NOTE: This very well may suck. Look at all this tight coupling…
			var id = e.target.id,
				value = e.target.value;

			this.model.attributes[id] = value;
			var validationType = ($(e.target).data('validation')) ? $(e.target).data('validation') : false;
			if(validationType && value.length > 0 && !this.model[validationType](value)) {
				this.showError(id);
			}
		},

		saveFormState: function() {
			// this.model.set({
			// 'account_email': $('#account_email').val(),
			// 'account_password': $('#account_password').val()
			// });
		},

		handleSubmit: function(e) {
			var self = this;
			$('.error-message').hide();
			this.saveFormState();
			var validationErrors = this.model.validationErrors;
			if(validationErrors.length > 0) {
				e.preventDefault();

				_.each(validationErrors, function(error) {
					self.showError(error.message);
				});
			}
		},

		manageEthnicityOptions: function(e) {
			var options = $('.race'),
				othersChecked = [];

			if('ethnicity-hispanic' === e.target.id) {
				_.each(options, function(option) {
					if(option.checked === true)
						othersChecked.push(option);

					option.checked = false;
				});

				if(othersChecked.length > 0)
					$('#ethnicity-hispanic')[0].checked = true;

			} else {
				$('#ethnicity-hispanic')[0].checked = false;
			}
		},

		sameShippingAddress: function(e) {
			// console.log(e.target);
			if(e.target.checked === true) {

			}
		},

		/*
		showThumbnailFilename: function(e) {
			// var reset = ' <small>(<a href="#" id="thumbnail-reset">undo</a>)</small>';
			$('#thumbnail-file').html($('#thumbnail').val());
		},

		resetThumbnail: function(e) {
			e.preventDefault();
			var html = $('#thumbnail')[0].innerHTML;
			$('#thumbnail')[0].innerHTML = html;
		}
		*/
	});
}(app.module('account')));
