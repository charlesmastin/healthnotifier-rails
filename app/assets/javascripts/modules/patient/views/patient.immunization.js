(function (Patient, Medication) {
  "use strict";
  Patient.Views.Immunization = Patient.Views.Collection.extend({
    // app.messages.WARNING_DELETE_IMMUNIZATION

    addOne: function(model) {

      var count = model.get('record_order') || this.count,
        validation = {
          'health_event': {
            required: true
          },
          start_date_formatted: {
            required: false,
            naturalDate: 1
          }
        };


      model.validation = validation;
      model.set({
        record_order: count
      });

      var hasRecords = 0;
      if (model.get('patient_id')) {
        if (count === 0) {
          //##at should order this from the db source so all SYSTEM/NONE records are presented first
          hasRecords = (model.get('immunization') == 'NONE') ? 0 : 1;
          this.$("input[name=immunizations][value="+hasRecords+"]").attr('checked', 'checked');

          if (!hasRecords) {
            model.set('immunization','');
            model.set('start_date_formatted',null);
          }
        }
      }

      var self = this;
      var view = new Patient.Views.CollectionItem({model: model, template: _.template($('#immunization-item').html()) });

      this.$('.entries').append(view.render().el);
      view.$('[name=start_date_formatted]').val(model.get('start_date_formatted'));
      $('#immunizationdate-' + count).placeholder();
      this.views.push(view);

      if (count > 0 || hasRecords) {
        this.$('.entries').show();
      }

      this.addAutocomplete(view.$('.immunization'), 'immunization', function(data, cb) {
        var items = _.map(data.combinations, function(combination) {
          return {
            label: combination.title,
            value: combination.title,
            code: combination.code,
            icd_type: combination.kndg.source,
            icd_code: combination.kndg.code
          };
        });
        cb(items);
      });

      view.$('.immunization').on('autocompleteselect', function(event, ui) {
        event.target.disabled = true;

        $('#immunization-' + count + '-name').val(ui.item.label);
        $('#immunization-' + count + '-imo').val(ui.item.code);

        var icd_type = ui.item.icd_type.toLowerCase(),
            icd_selector = '#immunization-' + count + '-' + icd_type;
        $(icd_selector).val(ui.item.icd_code);

        var icdCodeName = ui.item.icd_type.toLowerCase() + '_code';
        model.set('health_event', ui.item.label);
        model.set('imo_code', ui.item.code);
        if (ui.item.icd_code.indexOf('icd')) {
          model.set(icdCodeName, ui.item.icd_code);
        }
      });

      var $privacy = view.$('.privacy'),
        privacy = model.get('privacy'),
        selectText = '&mdash;'; // should not have a default value here

      //Make sure to set the custom select text after finding the proper option
      $('option', $privacy).each(function(index, option) {
        if(option.value === privacy) {
          selectText = option.innerHTML;
          $privacy[0].selectedIndex = index;
          return false;
        }
      });

      // handle the custom selection action, if relevant
      $('.custom-select span span', $privacy.parent()).html(selectText);

      if(model.isNew()){
        this.collection.add(model);
      }

      this.count++;
    },

    preSave: function(req_object) {
      //Last chance to remove things that will make service barf
      _.each(req_object.patient_health_events, function(condition) {
        delete condition.start_date_formatted;
      });
    },

    isValid: function() {
      var childFormsValid = true;
      _.each(this.views, function(child) {
        child.model.validate();
        if(childFormsValid === true && child.model.isValid() === false) {
          childFormsValid = false;
        }
      });

      return childFormsValid;
    }
  });
}(app.module('patient'), app.module('medication')));
