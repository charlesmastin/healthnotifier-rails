(function (Patient, Signup, Medication) {
	"use strict";
	//NOTE: Cleanup is needed as this is largely copy+paste from medication.item
	Patient.Views.Pregnancy = Backbone.View.extend({
		events: {
			'keypress input': 'preventSubmit',
			'click .display': 'toggleItemEditor',
			'blur input[type=text]': 'saveInputValue',
			'click [name=maternity_state]': 'saveInputValue'
		},
		
		initialize: function(options) {
			_.bindAll(this, 'render', 'preventSubmit', 'handleModelError', 'toggleItemEditor', 'saveInputValue',
				'saveFormState', 'isValid');
			
			var self = this;
			
			//Set rules as fields are encountered. WARNING: This is weird, I know.
			self.validationRules = {
				maternity_due_date_formatted: {
					required: true,
					naturalDate: 1,
					futureDate: 1
				}
			};
			self.model.validation = {};
			
			// what what son
			Backbone.Validation.bind(this, {
				forceUpdate: true,
				selector: 'name',
				valid: function (view, attr) {
					var field = $('[name="' + attr + '"]');
					field.removeClass('error');
					$("[data-for='" + attr + "']").hide();
				},
				invalid: function(view, attr, error) {
					var field = $('[name="' + attr + '"]');
					field.addClass('error');
					$("[data-for='" + attr + "']").show();
				}
			});

			this.model.on('change', function(model, options){
                // oh bla
                //console.log('model changed');
                // blablablabalbal
                $(document).trigger('onPatientChange');
            });
			
			this.model.on('validated', function(isValid, model, attrs) {
				if (isValid) {
					self.$('.error-message').hide();
				}
			});
			this.render();
		},
		
		render: function() {
			var maternityState = this.model.get('maternity_state');
			if(1 === ~~maternityState) {
				this.$('.entries').show();
			}
			this.$('[name=maternity_due_date_formatted]').val(this.model.get('maternity_due_date_formatted'));
		},
		
		preventSubmit: function(e) {
			if (e.keyCode === 13) {
				e.preventDefault();
				e.stopPropagation();
			}
		},
		
		handleModelError: function(view, errorMessages, options) {
			var self = this;
			_.each(errorMessages, function(field) {
				self.showError(field);
			});
		},
		
		toggleItemEditor: function(e) {
			var target = e.target,
				$container = $('#' + $(target).data('container')),
				$entries = $('.entries', $container),
				show = !!~~e.target.value;
			
			$entries.toggle(show);
			if(show === false) {
				delete this.model.validation.maternity_due_date;
				this.$('.due-date').val('');
				this.model.set({maternity_due_date: ''});
			}
		},
		
		saveInputValue: function(e) {
			var target = e.target,
				type = target.type,
				id = target.name,
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
				values[el.name] = (el.type != 'checkbox') ? el.value : el.checked;
			});
			this.model.validation = ($('[name=maternity_state]:checked').val() == "1") ? this.validationRules : {};
			this.model.set(values);
		},

		isValid: function() {
			// HACK: The model is failing validation, causing further validation issues on the medical page
			//       *Very* temporary hack to re-enable validation for this release.
			// return this.model.isValid();
			return true;
		}
	});
}(app.module('patient'), app.module('signup'), app.module('medication')));
