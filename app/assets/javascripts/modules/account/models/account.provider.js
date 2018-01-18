// LOL
(function (Provider, Residence) {
  "use strict";
  Provider.Model = Residence.Model.extend({
    defaults: {
      provider_credential_id: undefined,
      expiration: '',
      license_number: '',
      licensing_state_province: '',
      licensing_country: 'US',
      licensing_board: '',
      patient_id: undefined,
      supervisor_name: '',
      supervisor_contact_email: '',
      supervisor_contact_phone: '',
      supervisor_contact_phone_ext: '',
      credential_file: undefined,
      deleted_documents: [],
      '_destroy': false//,
      // record_order: 0
    },

    idAttribute: 'provider_credential_id',

    validation: {
      expiration: {
        required: true
      },
      license_number: {
        required: true
      },
      licensing_country: {
        required: true
      },
      licensing_board: {
        required: true
      },
      supervisor_name: {
        required: true
      },
      supervisor_contact_email: {
        required: true,
        pattern: 'email'
      },
      supervisor_contact_phone: {
        required: true
      },
    },

    initialize: function () {
      _.bindAll(this, 'isEmpty');
      this.on('change', this.evictIllegals);
      this.evictIllegals();
      this.collection_name = 'provider_credentials';
    },

    isEmpty: function() {
      var self = this;
      var fields = _.filter(self.defaults, function(field) {
        return (field !== '_destroy' && field !== 'record_order');
      });
      return _.all(fields, function(item) {
        return !self.get(item);
      });
    }
  });


  Provider.List = Residence.List.extend({
    model: Provider.Model,

    initialize: function (models, options) {
      Residence.List.prototype.initialize.apply(this, arguments);
      this.patient_id = options.patient_id;
      this.collection_name = 'provider_credentials';
    }

    //Do fun stuff here like custom comparator based on 'order'
  });
}(app.module('provider'), app.module('residence')));
