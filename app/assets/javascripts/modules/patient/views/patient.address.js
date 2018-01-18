(function (Patient, Medication) {
    "use strict";
    Patient.Views.Address = Patient.Views.Collection.extend({

        // app.messages.WARNING_DELETE_RESIDENCE
        count: 0,
        views: [],
        
        events : _.extend({
            'change select[name="lifesquare_location_type"]': 'handleLocationChange',
            'change select[name="country"]': 'handleCountryChange',
            // oh lordy Lord
            'change input[name="address_line1"]': 'validateAddress',
            'change input[name="address_line2"]': 'validateAddress',
            'change input[name="city"]': 'validateAddress',
            'change select[name="state_province"]': 'validateAddress',
            'change input[name="postal_code"]': 'validateAddress'
        }, Patient.Views.Collection.prototype.events),

        handleLocationChange: function(event){
            // FIXME: kinda ghetto workaround solution
            if($(event.currentTarget).val() == 'Other'){
                $(event.currentTarget).parents('div.item').find('.lifesquare-location-other').show();
                $(event.currentTarget).parents('div.item').find('.lifesquare-location-other input').focus();
                // TODO: did we have an existing value?
            }else{
                if($(event.currentTarget).val()){
                    $(event.currentTarget).parents('div.item').find('.lifesquare-location-other').hide();
                    $(event.currentTarget).parents('div.item').find('input[name="lifesquare_location_other"]').val('').trigger('blur');
                }
            }
        },

        handleCountryChange: function(event) {
            // TODO: handle actual usage focus, not really a big deal son
            if($(event.currentTarget).val() == 'US'){
                $(event.currentTarget).parents('div.item').find('select.state_province').show();
                $(event.currentTarget).parents('div.item').find('input.state_province').hide();
            }else{
                $(event.currentTarget).parents('div.item').find('select.state_province').hide();
                $(event.currentTarget).parents('div.item').find('input.state_province').show();
            }
        },

        validateAddress: function(e){
            var view = this.views[$(e.currentTarget).parents('div.item').index()];
            var model = view.model;

            // OK, ONLY ONLY ONLY for US residences
            if(model.get('country') != 'US'){
                console.log('TODO: international address validation');
                return;
            }

            // if the model is valid, or maybe just if the address part is
            if(!model.get('_validated') && model.get('address_line1') != '' && model.get('city') != '' && model.get('state_province') != '' && model.get('postal_code') != ''){
                if(model.isNew() || model.hasChanged()){
                    // not perfect but this should do for most cases
                    // TODO: Dry this up so we can use it on all the address entry forms, or something cool
                    var address = model.get('address_line1') + ', ';
                    // yes / no good thing, bad thing?
                    if(model.get('address_line2') != ''){
                        address += model.get('address_line2') + ', ';
                    }
                    address += model.get('city') + ', ';
                    address += model.get('state_province') + ' ';
                    address += model.get('postal_code') + ', ';
                    address += 'USA'; // MERICA!
                    // so awkwardly the validation call happens in the collection view controller, vs say the individual view, or the model, W/E
                    // gotta love this craptictecture
                    $.ajax({
                        url: '/api/v1/validate-address/',
                        type: 'GET',
                        dataType: 'json',
                        contentType: 'application/json',
                        data: { address: address },
                        success: function(data){
                            if(data.match === true){
                                // exact match, proceed
                                model.set('_validated', true);
                            } else if(data.match === false && data.results.length){
                                // show the UI for selecting the results
                                $('#address-validator').reveal({
                                    animation: 'fade'
                                });
                                var addressValidator = new Patient.Views.ValidateAddress({ el: '#address-validator', model: model, results: data.results, address: address});
                            }else if(data.results.length == 0){
                                // this error should show only once, because it will just keep blasting as you attempt to remedy the crap address info
                                // ain't no matches to pick from
                                // confirm()
                                // window.alert('No matches found, address may be invalid and unreachable for shipping');
                            } else {
                            }
                        },
                        error: function(data){
                            app.alert('Address Validation Fail');
                        }
                    });

                }
            }
            // if it's new record

            // if existing and there is a dirty flag on the model

            // issue request to api for verification

            // render results for confirmation somehow, modal with radios, or something
        },
        
        initialize: function(){
            Patient.Views.Collection.prototype.initialize.apply(this, arguments);
            // scope on that shizzle
            this.collection.on("change:_validated", this.handleValidated, this);
        },

        handleValidated: function(model, value, options){
            // because of the super non-standard way we (og lifesquare) has setup the addone, we can't easily addOne and re-render both existing and new models, not exactly
            for(var i=0;i<this.views.length;i++){
                if(this.views[i].model.cid == model.cid){
                    // update the changed attributes
                    var v = this.views[i];
                    // this is 2006 all over again, but in 2016, fun
                    v.$el.find('input[name="address_line1"]').val(model.get('address_line1'));
                    v.$el.find('input[name="city"]').val(model.get('city'));
                    v.$el.find('input[name="postal_code"]').val(model.get('postal_code'));
                    v.$el.find('select[name="state_province"]').val(model.get('state_province'));
                    break;
                }
            }
        },

        removeView: function(view){
            // attempt to splice it out son, lolzin
            // we need to do an exhuastive study on the collection mechanism for this
            // this seems totally logical to me;
            for(var i=0;i<this.views.length;i++){
                if(this.views[i].cid == view.cid){
                    var plucked = this.views.splice(i, 1);
                    plucked = null;
                    view = null;
                    // assumption garbage collection is gonna kick in
                }
            }
        },

        postInitialize: function() {
            // Set the mailing address radios correctly
            var self = this;
            $.each(self.collection.models, function(index) {
                var radio = $('#signup-address-mailing-address-' + this.attributes.record_order);
                if (this.attributes.mailing_address) {
                    radio.attr('checked', 'checked');
                }
            });
        },
        
        addInitial: function(model) {
            // Add the initial address
            this.addOne(model);
            // addOne showed the delete button, so hide it again
            //$('.destroy-container').hide();
            // Set this address as the mailing address
            $('#signup-address-mailing-address-0').attr('checked', 'checked');
        },
        
        addOne: function(model) {
            var count = model.get('record_order') || this.count,
                validation = {
                    'address_line1': {
                        required: true
                    },
                    'city': {
                        required: true
                    },
                    'state_province': {
                        required: true,
                        // pattern: /^[a-z]{2}$/i
                    },
                    'postal_code': {
                        required: true
                        // pattern: 'usPostalCode'
                        // usPostalCode: 1
                    },
                    'country': {
                        required: true
                    },
                    'residence_type': {
                        required: true
                    },
                    'lifesquare_location_type': {
                        required: true
                    }
                };
            model.validation = validation;
            model.set({
                record_order: count
            });
            
            var view = new Patient.Views.CollectionItem({model: model, template: _.template($('#address-item').html())});
            var scope = this;

            view.remove = function () {
                view.$el.remove();
                if(!view.model.isNew()){
                    view.model.set('_destroy', true);
                }
                this.model.validation = {};
                this.validationRules = {};
                //HACK: Yes, this stinks.
                this.model.validate = function() { return true; }
                this.model.isValid = function() {return true; }
                // When the address is removed, if it was the mailing address, and
                // any other addresses remain, set the first one as the mailing address
                var anyChecked = false;
                var radios = $('.mailing-address-radio');
                if (radios) {
                    radios.each(function() {
                        if ($(this).attr('checked') == 'checked') {
                            anyChecked = true;
                            return;
                        }
                    });
                    if (!anyChecked) {
                        radios.first().attr('checked', 'checked');
                    }
                }
                
                // OH SNAP, manual garbage collection just for giggles, although it appeared to work
                if(view.model.isNew()){
                    scope.collection.remove(view.model);
                    scope.removeView(view);
                }
            };
            
            this.$('.entries').append(view.render().el);
            this.views.push(view);
            
            var $residence = view.$('.residence_type'),
                residenceType = model.get('residence_type'),
                selectText = 'Home';
            
            //Make sure to set the custom select text after finding the proper option
            if (residenceType != undefined) {  // Home is default if this is a new address
                $('option', $residence).each(function(index, option) {
                    // TODO this looks suspect
                    if(option.value.toUpperCase() === residenceType.toUpperCase()) {
                        selectText = option.innerHTML;
                        $residence[0].selectedIndex = index;
                        return false;
                    }
                });
            //If no option has been selected (new residence) set "HOME" as selected
            } else {
                $('option', $residence).each(function(index, option) {
                    if(option.value === 'HOME') {
                        selectText = option.innerHTML;
                        model.set('residence_type', option.value);
                        $residence[0].selectedIndex = index;
                        return false;
                    }
                });
            }
            $('.custom-select span span', $residence.parent()).html(selectText);

            // set country / state stuffs
            view.$('.country').val(model.get('country'));
            view.$('.state_province').val(model.get('state_province'));
            view.$('.country').trigger('change');// ghetto workaround to initial view state

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

            var ll = model.get('lifesquare_location_type');
            view.$('.lifesquare_location_type').val(model.get('lifesquare_location_type'));
            if(ll == ""){
                // init default state son
            }else if (ll == "Other"){
                view.$el.find('.lifesquare-location-other').show();
            }else {
                //
            }

            // Now there are multiple addresses, so let them be deleted
            // That's not true when adding the first one, but addInitial
            //   hides the delete button again
            $('.destroy-container').show();
            
            // meh? this is dirty but oh well, hope it doesn't stack!
            // this.collection.on("change:_validated", this.handleValidated, this);
            if(model.isNew()){
                // BAD THING COULD COME, MOST LIKELY, but they didn't
                this.collection.add(model);
            }
            this.count++;
        },
        
        preSave: function(req_object) {
            // Fix values of mailing address radios
            var residences = req_object.patient_residences;
            if (residences) {
                $.each(residences, function(index) {
                    var radio = $('#signup-address-mailing-address-'
                                  + this.record_order);

                    if(radio.is(":checked")){
                        this.mailing_address = true;
                    }else{
                        this.mailing_address = false;
                    }

                    delete this['_validated'];
                    delete this['_validation_override'];
                });
                // slap it down SON INT ALL DAY UP ON THAT THING
            }
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
