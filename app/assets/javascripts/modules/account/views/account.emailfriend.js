(function (Account) {
	"use strict";
	Account.Views.EmailFriend = Backbone.View.extend({
		events: {
			'blur input': 'saveInputValue',
			'blur select': 'saveInputValue',
			'change select': 'saveInputValue',
			'submit form': 'sendEmail',
			'click .close-reveal-modal': 'renderAfterDelay'
		},
		
		initialize: function() {
			_.bindAll(this, 'render', 'renderAfterDelay', 'sendEmail', 'saveInputValue', 'saveFormState', 'isValid');
			
			var self = this;
			
			self.validationRules = self.model.validation;
			self.model.validation = {};
			
			Backbone.Validation.bind(this, {
				forceUpdate: true,
				selector: 'name',
				valid: function (view, attr) {
					$('#' + attr).removeClass('error');
					$("[data-for='" + attr + "']").hide();
				},
				invalid: function(view, attr, error) {
					$('#' + attr).addClass('error');
					$("[data-for='" + attr + "']").show();
				}
			});
			
			this.model.on('validated', function(isValid, model, attrs) {
				if (isValid) {
					self.$('.error-message').hide();
				}
			});
			
			this.render();
		},
		
		render: function() {
			var $message = this.$('.message');
			
			//Reset values
			this.$('.emails').val('');
			this.$('.name').val('');
			$message.val($message.text());
			
			//Reset stages (acceptance first)
			this.$('section').show();
			this.$('.successful-email').hide();
		},
		
		renderAfterDelay: function(e) {
			var self = this,
				delay = setTimeout(function() {
					self.render.call(self);
				}, 500);
		},
		
		sendEmail: function(e) {
			e.preventDefault();
			
			if(!this.isValid())
				return false;
			
			var self = this,
				$alert = self.$('.error'),
				$btn = self.$('[type=submit]'),
				orgButtonText = $btn.text();
			
			$alert.html('');
			$btn.text('Sending...').attr('disabled', true);
			
			$.ajax({
				url: '/account/email_friend',
				type: 'POST',
				data: {
					emails: self.$('.emails').val(),
					name: self.$('.name').val(),
					message: self.$('.message').val()
				},
				success: function(data) {
					self.$('section').hide();
					self.$('.successful-email').show();
					$btn.text(orgButtonText).attr('disabled', null);
				},
				error: function() {
					$alert.html('<b>There was an error sending your email. Please try again.</b>');
					$btn.text(orgButtonText).attr('disabled', null);
				}
			});
		},
		
		saveInputValue: function(e) {
			var target = e.target,
				type = target.type,
				id = target.id,
				//NOTE: Not very robust. Needs better betterness.
				value = (type != 'checkbox') ? target.value : target.checked;
			
			if (this.validationRules[id]) {
				this.model.validation[id] = this.validationRules[id];
			}
			this.model.set(id, value);
		},
		
		saveFormState: function() {
			var values = {};
			_.each($('input:visible, select', this.$el), function(el) {
				if(el.id)
					values[el.id] = el.value;
			});
			this.model.validation = this.validationRules;
			this.model.set(values);
		},
		
		isValid: function() {
			this.saveFormState();
			this.model.validate();
			return this.model.isValid();
		}
	});
})(app.module('account'));


(function(EmailFriend) {
	EmailFriend.Model = Backbone.Model.extend({
		validation: {
			account_name: {
				required: true
			},
			account_emails: function(value) {
				//Modified from Backbone.Validation to allow multiple entries
				var pattern = /((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))/i;
				if(!value || !value.match(pattern)) {
					return 'Error';
				}
			}
		}
	});
})(app.module('emailfriend'));
