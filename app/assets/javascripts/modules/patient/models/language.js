(function (Patient) {
	"use strict";
	Patient.Models.Language = Patient.Models.CollectionItem.extend({
		defaults: _.extend({
			patient_language_id: undefined,
			language_code: 'en',
			language_proficiency: 'NATIVE',
		}, Patient.Models.CollectionItem.prototype.defaults),

		idAttribute: 'patient_language_id',
		
		validation: {
			language_code: {
				required: true
			},
			language_proficiency: {
				required: true
			}
		},
		
		initialize: function () {
			_.bindAll(this, 'evictIllegals', 'isNew', 'url', 'isEmpty');
			this.id = this.get('patient_language_id');
			delete(this.defaults.privacy);
			this.on('change', this.evictIllegals);
			this.evictIllegals();
			this.collection_name = 'patient_languages';
		},

		evictIllegals: function() {
			var self = this,
				allowed = _.keys(this.defaults);

			_.each(self.attributes, function(value, key) {
				if(!!~allowed.indexOf(key) === false) {
					delete self.attributes[key];
				}
			});
		},
		
		isNew: function() {
			return this.id ? false : true;
		},
		
		url: function() {
			return '/api/v1/profiles/' + this.get('patient_uuid') + '/' + this.collection_name;
		},
		
		isEmpty: function() {
			var self = this;
			return _.all(['language_code','language_proficiency'], function(item) {
				return !self.get(item);
			});
		}
	});
	
	Patient.Collections.Language = Patient.Collections.Collection.extend({
		model: Patient.Models.Language,
		
		initialize: function (models, options) {
			_.bindAll(this, 'url', 'save');
			Patient.Collections.Collection.prototype.initialize.apply(this, arguments);
			this.patient_uuid = options.patient_uuid;
			this.collection_name = 'patient_languages';
		},
		
		url: function() {
			return '/api/v1/profiles/' + this.patient_uuid + '/' + this.collection_name;
		},

		save: function() {
			return this.map(function(model) {
				return model.save();
			});
		}
	});
}(app.module('patient')));
