(function (Patient, Medication) {
    "use strict";
    Patient.Views.Medication = Patient.Views.Collection.extend({
        // app.messages.WARNING_DELETE_MEDICATION
        count: 0,
        views: [],

        addOne: function(model) {

            var count = model.get('record_order') || this.count,
                validation = {
                    'therapy': {
                        required: true
                    }
                };

            model.validation = validation;
            model.set({
                record_order: count
            });

            var hasRecords = 0;
            if (model.get('patient_id')) {

                if (count == 0) {
                    //##at should order this from the db source so all SYSTEM/NONE records are presented first
                    hasRecords = (model.get('therapy') == 'NONE') ? 0 : 1;
                    this.$("input[name=medications][value="+hasRecords+"]").attr('checked', 'checked');

                    if (!hasRecords) {
                        model.set('therapy','');
                        model.set('therapy_strength_form','');
                        model.set('therapy_frequency','');
                        model.set('therapy_quantity','');
                    }
                }
            }

            var view = new Patient.Views.CollectionItem({model: model, template: _.template($('#medication-item').html()) });

            this.$('.entries').append(view.render().el);
            this.views.push(view);

            if (count > 0 || hasRecords) {
                this.$('.entries').show();
            }

            var $searchInput = view.$('.medication-name'),
                $doseSelect = view.$('.dose');

            this.addAutocomplete($searchInput, 'medication', function(data, cb) {
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

            $searchInput.bind('autocompleteselect', function(event, ui) {
                $doseSelect.attr('disabled', true);

                var icd_type = ui.item.icd_type.toLowerCase(),
                    icd_selector = '#therapy-' + count + '-' + icd_type;
                $(icd_selector).val(ui.item.icd_code);

                var icdCodeName = ui.item.icd_type.toLowerCase() + '_code';
                model.set('health_event', ui.item.label);
                model.set('imo_code', ui.item.code);
                if (ui.item.icd_code.indexOf('icd')) {
                    model.set(icdCodeName, ui.item.icd_code);
                }

                $.ajax('/api/v1/term-lookup/medication', {
                    data: {
                        med_name: ui.item.label
                    },
                    dataType: 'json',
                    success: function(data, textStatus, jqXHR) {
                        $doseSelect.empty();

                        if(data.routes.length > 0) {
                            $doseSelect.attr('disabled', null);

                            $('<option>', {
                                html: '&mdash;',
                                val: null,
                            }).appendTo($doseSelect);

                            $.each(data.routes, function(index, item) {
                                $('<option>', {
                                    text: item,
                                    val: item,
                                }).appendTo($doseSelect);
                            });

                            $('<option>', {
                                html: '&mdash;',
                                val: null,
                            }).appendTo($doseSelect);
                            $('<option>', {
                                html: 'Other',
                                val: 'Other',
                            }).appendTo($doseSelect);

                            //Custom selector doesn't like programmatic selections
                            $('.custom-select span span', $doseSelect.parent()).html('&mdash;');
                        } else {
                            $('<option>', {
                                text: 'N/A',
                                val: 'N/A',
                                selected: 'selected'
                            }).appendTo($doseSelect);

                            $doseSelect.attr('disabled', true);

                            //Custom selector doesn't like programmatic selections
                            $('.custom-select span span', $doseSelect.parent()).text('N/A');
                        }
                    },
                    error: function(jqXHR, textStatus, errorThrown) {
                        $doseSelect.attr('disabled', null);
                        console.log('error: ' + textStatus);
                    },
                });
            });

            $searchInput.bind('autocompleteopen', function(event, ui) {
                    $doseSelect.empty();
            });

            var doseVal = model.get('therapy_strength_form');
            if (doseVal) {
                //##at need to customize the select list for the base drug
                $doseSelect.empty();
                $doseSelect.attr('disabled', null);
                $('<option>', {
                    text: doseVal,
                    val: doseVal,
                    selected: 'selected'
                }).appendTo($doseSelect);
                $('.custom-select span span', $doseSelect.parent()).text(doseVal);
            }

            view.$('.therapy_frequency').val(model.get('therapy_frequency'));
            view.$('.therapy_quantity').val(model.get('therapy_quantity'));

            // FIXME: hmm, seems really labor intensive to setup property - UI binding
            // jquery supports more straightforward assignment as well, probably should simplify
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

        isValid: function() {
            var self = this;
            if (this.$("input[name=medications]:checked").val() == 0 && this.views.length > 0) {
                // Set this patient explicitly to no meds
                this.views[0].model.set('therapy','NONE');
                // remove the rest if present
                //this.views.splice(1);
                var i = 0;
                _.each(this.views, function(view) {
                    if (i++ > 0)
                        view.model.set('_destroy',true);
                });
                return true;
            }
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
