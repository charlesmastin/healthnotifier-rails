(function (Patient) {
	"use strict";
	Patient.Views.Profile = Backbone.Abide.extend({
		defaults: {
		},

		events: {
			'click button[type="submit"]': 'handleSubmit',
			//'click .edit-headshot': 'imageEditor',
			//'click #user-headshot-link': 'imageEditor',
			// 'click #mailing-is-home': 'saveInputValue',
            'click a.privacy-control': 'showPrivacyMenu',
			'change input': 'saveInputValue',
			'blur input': 'saveInputValue',
			'blur select': 'saveInputValue',
			'change select': 'saveInputValue',
			'click [type=checkbox]': 'saveInputValue',
			'click #provider': 'toggleProvider',

			'keyup #birthdate_formatted': 'handleDobUp',
            'keypress #birthdate_formatted': 'handleDobDown',

            // NAME TOWN DOWN BROWN STOWN
            'keyup #first_name': 'handleNameUpdate',
            'keyup #middle_name': 'handleNameUpdate',
            'keyup #last_name': 'handleNameUpdate',
            'keyup #name_suffix': 'handleNameUpdate'

		},

		initialize: function(options) {
			_.bindAll(this, 'render', 'showPrivacyMenu', 'setPrivacy', 'imageEditor', 'updateThumbnailButtonText',
				'saveInputValue', 'saveFormState', 'isValid', 'handleNameUpdate');

			var self = this;

			self.validationRules = self.model.validation;
			self.model.validation = {};
			self.$uploadTrigger = self.$('button.edit-headshot');

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

			this.thumbnailView = null;
			this.render();

            // but we need this on keydown of those fields, specifically not just change yea son, get funky with it
            /*
            this.model.on("change:first_name change:last_name change:middle_name change:name_suffix", function(model, options){
                console.log('DONKEY NUTS SUPREME');
            });
            */

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
			}).on('change:photo_uid', function() {
				var uid = self.model.get('photo_thumb_crop_params');
				self.updateThumbnailButtonText(uid ? 'edittext' : 'defaulttext');
			});

			// chain gang
			this.on('done', function(e) {
				document.location.href = $('#signup-personal').attr('data-action');
			});
		},

        handleNameUpdate: function(e){
            e.preventDefault();
            // do the logic for formatting here? vs there, meh, six and a half dozen blablablabla™
            // having a hard time getting the "current raw value"
            // flip yourself silly
            $(document).trigger('onPatientNameChange', [{
                first_name: $('#first_name').val(),
                last_name: $('#last_name').val(),
                middle_name: $('#middle_name').val(),
                suffix: $('#name_suffix').val()
            }]);
        },

        showPrivacyMenu: function(e){
            var scope = this;
            e.preventDefault();
            // calculate index? is that safe? hmmm maybe?
            var attr = $(e.currentTarget).parents('.component.privacy-control').attr('data-attr');
            var pop = popover.show(e, $(e.currentTarget).attr('data-popover'));
            pop.on('click', 'a.privacy', function(e){
                scope.setPrivacy(attr, $(e.currentTarget).attr('data-privacy'));
                pop.off('click'); // meh, cheap town
                // ghetto blast times here
                popover.hide('privacy-control');
                return false;
            });
            // we could a- listen to that dom element
            // then detach upon hearing the popover hidden biziness
            return false;
        },

        setPrivacy: function(attr, privacy){

            //this.views[index].model.set('privacy', privacy);
            // this is quite possibly the most hackterrific code I know, well par for da course son
            // update the privacy icon
            // update the classes on the i
            this.model.set(attr, privacy);
            // FML SON, but this is WAY easier than trying out react
            var icon = this.$el.find('.component.privacy-control[data-attr="'+attr+'"] i');
            // privacy options conditional duplication 1000
            icon.removeClass().addClass('material-icons').addClass('privacy-'+privacy);
            switch(privacy){
                case 'public':
                    icon.text('people');
                break;
                case 'provider':
                    icon.text('verified_user');
                break;
                case 'private':
                    icon.text('lock');
                break;
            }
        },

		render: function() {
			var $height = this.$('[name=imperialHeight]'),
				$weight = this.$('[name=imperialWeight]'),
				existingHeight = this.model.get('height') || $height.val(),
				existingWeight = this.model.get('weight') || $weight.val();

			if(existingHeight) {
				this.model.set('height', existingHeight, {silent: true});
			}

			if(existingWeight) {
				this.model.set('weight', existingWeight, {silent: true});
			}

			$height.val(this.model.get('imperialHeight'));
			$weight.val(this.model.get('imperialWeight'));

			var uid = this.model.get('photo_thumb_crop_params');
			this.updateThumbnailButtonText(uid ? 'edittext' : 'defaulttext');

			//
			// FIXME: hmm, seems really labor intensive to setup property - UI binding
			// jquery supports more straightforward assignment as well, probably should simplify
			var $demographics_privacy = this.$('select[name="demographics_privacy"]'),
				demographics_privacy = this.model.get('demographics_privacy'),
				selectText = '&mdash;'; // should not have a default value here

			//Make sure to set the custom select text after finding the proper option
			$('option', $demographics_privacy).each(function(index, option) {
				if(option.value === demographics_privacy) {
					selectText = option.innerHTML;
					$demographics_privacy[0].selectedIndex = index;
					return false;
				}
			});


			// handle the custom selection action, if relevant
			$('.custom-select span span', $demographics_privacy.parent()).html(selectText);


			// FIXME: hmm, seems really labor intensive to setup property - UI binding
			// jquery supports more straightforward assignment as well, probably should simplify
			var $biometrics_privacy = this.$('select[name="biometrics_privacy"]'),
				biometrics_privacy = this.model.get('biometrics_privacy'),
				selectText = '&mdash;'; // should not have a default value here

			//Make sure to set the custom select text after finding the proper option
			$('option', $biometrics_privacy).each(function(index, option) {
				if(option.value === biometrics_privacy) {
					selectText = option.innerHTML;
					$biometrics_privacy[0].selectedIndex = index;
					return false;
				}
			});

			// handle the custom selection action, if relevant
			$('.custom-select span span', $biometrics_privacy.parent()).html(selectText);



			return this;
		},

		handleSubmit: function(e) {
			// this won't matter, since we're not a form
			// e.preventDefault();
			this.submit(e);
			// added for the non form based approach
			return;
		},

		handleDobDown: function(e){
            window.app.handleDobDown(e);
        },

        handleDobUp: function(e){
            window.app.handleDobUp(e);
        },

		imageEditor: function(e) {
			
			try {
				e.preventDefault();
				e.stopPropagation();
			} catch(exception) {

			}
			var self = this;

			$('#user-headshot').reveal({
				animation: 'fade',
				closeonbackgroundclick: false
			});

			if (!self.thumbnailView) {
				self.thumbnailView = new Patient.Views.ProfilePhotoEditor({ el: '#user-headshot', model: self.model });
			}

			return false;
		},

		updateThumbnailButtonText: function(dataField) {
			var text = this.$uploadTrigger.data(dataField);
			this.$uploadTrigger.text(text ? text : this.$uploadTrigger.data('defaulttext'));
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

		toggleProvider: function(e) {
			$('#provider_form').toggle(e.target.checked);
		},

		isValid: function() {
			this.model.validate();
			return this.model.isValid();
		}
	});
}(app.module('patient')));
