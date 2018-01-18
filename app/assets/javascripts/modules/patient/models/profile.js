(function (Patient) {
	"use strict";

	var birthdateFormat = 'MM/DD/YYYY';

	Patient.Models.Profile = Backbone.Model.extend({
		defaults: {
			uuid: undefined,
			patient_id: undefined,
			first_name: '',
			middle_name: '',
			last_name: '',
			name_suffix: '',
			birthdate: '',
			birthdate_formatted: '',
			gender: '',
			ethnicity: '',
			hair_color: '',
			blood_type: '',
			eye_color_both: '',
			height: '',
			weight: '',
			medication_presence: '',
			allergy_presence: '',
			condition_presence: '',
			procedure_presence: '',
			directive_presence: '',
			immunization_presence: '',
			maternity_state: '', //it's like a fake valiator guy here son
			notes: '',
			maternity_due_date: '',
			maternity_due_date_mask: '',
			maternity_due_date_formatted: '',
			confirmed: 0,
			imperialHeight: '',
			imperialWeight: '',
			race: '',
			organ_donor: false,
			biometrics_privacy: 'provider',
			demographics_privacy: 'provider',
			photo_thumb_crop_params: '',
			searchable: true,
			bp_systolic: '',
			bp_diastolic: '',
			pulse: '',
		},

		mutators: {
			imperialWeight: {
				get: function() {
					var pounds = Math.round(this.weight * 2.20462262);
					return pounds > 0 ? pounds : undefined;
				},

				set: function(key, value, options, set) {
					var matches = value.match(/([0-9\.]+)/);
					if(matches !== null) {
						var pounds = value,
							kilos = pounds * 0.45359237;

						this.set('weight', kilos, options);
					} else {
						this.set('weight', '', options);
					}
				}
			},

			imperialHeight: {
				get: function() {
					var height = '',
						intHeight = ~~this.height;
					if(this.height !== null && this.height !== undefined && _.isNumber(intHeight) && intHeight > 0) {
						var totalInches = Math.round(this.height * 0.393700787),
							feet = Math.floor(totalInches / 12),
							inches = totalInches > 12 ? totalInches % 12 : 0;

						height =  feet + "' " + inches + '"';
					}

					return height;
				},

				set: function(key, value, options, set) {
					var measurements = value.match(/^([\d.]+)(?:[^\d]+)?([\d]+)?(?:[^\d]+)?$/);
					if(measurements !== null) {
						var inches = ~~measurements[1] * 12 + (measurements[2] ? ~~measurements[2] : 0),
							cm = inches * 2.54;

						this.set('height', cm, options);
					} else {
						// throw new Error('Incorrect height format');
						this.set('height', '', options);
					}
				}
			},

			maternity_due_date_formatted: {
				get: function() {
					var mask = this.maternity_due_date_mask,
						due_date = this.maternity_due_date,
						result = '';

					if (mask && due_date) {
						result = moment(due_date, 'YYYY-MM-DD').format(mask);
					} else if(due_date) {
						result = due_date;
					}

					return result;
				},

				set: function(key, value, options, set) {
					var occasion = new Occasion(value);
					set('maternity_due_date', occasion.machineDate, options);
					set('maternity_due_date_mask', occasion.mask, options);
					set('maternity_due_date_formatted', value, options);
				}
			},

			birthdate_formatted: {
				get: function() {
					return this.birthdate !== null ? moment(this.birthdate, 'YYYY-MM-DD').format('MM/DD/YYYY') : null;
				},

				set: function(key, value, options, set) {
					var occasion = new Occasion(value);
					if(occasion.isValid() && occasion.date.year() > 1899) {
						set({
							birthdate: occasion.machineDate,
							birthdate_formatted: value
						}, options);
					} else {
						set({
							birthdate: null,
							birthdate_formatted: null
						}, options);
					}
				}
			},

			race: {
				get: function() {
					return this.ethnicity;
				},
				set: function(key, value, options, set) {
					this.set('ethnicity', value);
				}
			},

			photo_thumb_crop_params_array: {
				get: function() {
					var result = null,
						plusSplit = this.photo_thumb_crop_params ? this.photo_thumb_crop_params.split('+') : [];

					if(plusSplit.length === 3) {
						var crop = plusSplit[0],
							origin_x = ~~plusSplit[1],
							origin_y = ~~plusSplit[2];

						var cropSplit = crop.split('x');
						if(cropSplit.length === 2) {
							var cropWidth = ~~[cropSplit[0]] + origin_x,
								cropHeight = ~~[cropSplit[0]] + origin_y;

							result = [origin_x, origin_y, cropWidth, cropHeight];
						}
					}

					return result;
				}
			}

		},

		// wow that was hard
		photo_thumb_crop_params_object: function(){
			var tA = this.get('photo_thumb_crop_params_array');
			if(tA != null && tA.length == 4){
				return {
					Width: parseInt(tA[2]),
					Height: parseInt(tA[3]),
					OriginX: parseInt(tA[0]),
					OriginY: parseInt(tA[1])
				}
			}else {
				return null;
			}
		},

		idAttribute: 'patient_id',

		id: 0,

		url: function() {
			return this.isNew() ? '/api/v1/profiles' : '/api/v1/profiles/' + this.get('uuid');
		},

		validation: {
			first_name: {
				required: true
			},
			last_name: {
				required: true
			},
			birthdate_formatted: {
				required: true,
				usDate: 1
			}
		},

		initialize: function () {
			_.bindAll(this, 'isNew', 'parse', 'evictIllegals');
			this.on('change', this.evictIllegals);
			this.evictIllegals();
		},

		isNew: function() {
			return this.id ? false : true;
		},

		parse: function(resp, xhr) {
			//Mutate Rails date serialziation
			if(resp.birthdate && /[\d]{4}-[\d]{2}-[\d]{2}/.test(resp.birthdate)) {
				var ymd = resp.birthdate.split('-');
				//moment & native Date() use zero-indexed for everything except year and day. Yes, that is crazy.
				ymd[1] = ''+(ymd[1]-1);
				resp.birthdate = moment(ymd).format(birthdateFormat);
			}

			return resp;
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
		}
	});


	Patient.List = Backbone.Collection.extend({
		model: Patient.Model
		//Do fun stuff here like custom comparator based on 'order'
	});
}(app.module('patient')));
