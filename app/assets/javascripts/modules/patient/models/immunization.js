(function (Patient) {
  "use strict";
  Patient.Models.Immunization = Patient.Models.CollectionItem.extend(
  {
    defaults: _.extend({
      start_date: undefined,
      start_date_mask: '',
      health_event_type: 'IMMUNIZATION',
      health_event: '',
      imo_code: '',
      icd9_code: '',
      icd10_code: '',
      patient_health_event_id: undefined,
    }, Patient.Models.CollectionItem.prototype.defaults),

    idAttribute: 'patient_health_event_id',

    mutators: {
      start_date_formatted: {
        get: function() {
          var mask = this.start_date_mask,
            date = this.start_date,
            result = '';

          if (mask && date) {
            result = moment(date, 'YYYY-MM-DD').format(mask);
          } else if(date) {
            result = date;
          }

          return result;
        },

        set: function(key, value, options, set) {
          var occasion = new Occasion(value);
          set({
            start_date: occasion.machineDate,
            start_date_mask: occasion.mask,
            start_date_formatted: value
          }, options);
        }
      }
    },

    initialize: function () {
      _.bindAll(this, 'isEmpty');
      this.on('change', this.evictIllegals);
      this.evictIllegals();
      this.collection_name = 'patient_health_events';
    },

    isEmpty: function() {
      var self = this;
      return _.all(['health_event'], function(item) {
        return !self.get(item);
      });
    }
  });

  Patient.Collections.Immunization = Patient.Collections.Collection.extend({
    model: Patient.Models.Immunization,

    initialize: function (models, options) {
      Patient.Collections.Collection.prototype.initialize.apply(this, arguments);
      this.patient_id = options.patient_id;
      this.collection_name = 'patient_health_events';
    }
  });
}(app.module('patient')));
