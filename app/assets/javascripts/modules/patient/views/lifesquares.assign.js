(function(Account, Patient) {
    "use strict";

    Patient.Views.LifesquaresAssign = Backbone.View.extend({
        events: {
            // submit for more than 1 patient
            'click [type="submit"]': 'submitForm',
            'click [name="subscription"]': 'dirtySubscriptionHandler',
            'focus #promo-code': 'focusPromo',
            'keyup #promo-code': 'keyupPromo',
            'blur #promo-code': 'blurPromo',
            'change #existing-card': 'toggleBillingInput'
        },
        
        initialize: function(options) {
            this.options = options;
            this.payload = null;
            this.requires_payment = true;
            this.requires_shipping = true;
            this.user_subscription = null;
            this.hadValidPromo = false;
            this.is_validating = false;
            this.promoHasFocus = false;

            this.validationInterval = null;

            // external submit button wire down town usa central timezone blowouts
            // event from outside
            $(document).off('click', '#action-transaction-save');
            $(document).on('click', '#action-transaction-save', function(e){
                e.stopImmediatePropagation();
                if($(e.currentTarget).hasClass('disabled')){
                    return false;
                }
                self.submitForm(e);
                return false;
            });

            _.bindAll(this, 'submitForm', 'validate', 'lockForm', 'unlockForm', 'buildPayload', 'submitToApi',
                'validationResponseHandler', 'stripeResponseHandler', 'dirtySubscriptionHandler', 'focusPromo', 'blurPromo', 'keyupPromo', 'updatePromoState');
            
            var self = this;
            var pills = this.options.pills || this.$('article.patient');
            
            // WTF MAN, get this outta here audi 5000 times
            self.initializeSession();
            self.on('sessionExpired', function() {
                document.location.href = self.sessionPath;
            }).on('sessionTimeoutWarning', function() {
                if(!self.timeoutView) {
                    self.timeoutView = new Account.Views.TimeoutWarning({ sessionManager: self });
                }
                self.timeoutView.render();
            });
                
            self.pillViews = [];
            _.each(pills, function(pill, index) {
                var code = $('.lifesquare-code', pill).html(),
                    model = new Patient.Models.Sticker({ patient_uuid: $(pill).attr('data-patient-uuid'), lifesquare_uid: code, code_exists: (code.length > 0) ? true : false }),
                    view = new Patient.Views.Sticker({ el: pill, index: index, model: model });
                self.pillViews.push(view);
            });
            
            $(document).off('onAssignValidateLifesquares');
            $(document).on('onAssignValidateLifesquares', function(e){
                e.stopImmediatePropagation();
                if(!self.is_validating){
                    self.validate();
                }else {
                    // queue up the validation??
                    console.log('already validating…');
                }
                return false;
            });
        },

        toggleBillingInput: function(e){
            if($(e.target).val() == ''){
                $('#stripe-card-fields-container').removeClass('hidden');
            }else{
                $('#stripe-card-fields-container').addClass('hidden');
            }
        },

        focusPromo: function(e){
            this.promoHasFocus = true;
            this.updatePromoState('loading');
        },

        keyupPromo: function(e){
            clearTimeout(this.validationInterval);
            var scope = this;
            this.valiationInterval = setTimeout(function(){
                if(scope.$('#promo-code').val().length || scope.hadValidPromo){
                    scope.validate();    
                }else {
                    scope.updatePromoState();
                } 
            }, 500);
        },

        blurPromo: function(e){
            this.promoHasFocus = false;
            // ONLY AT THIS POINT COMMUNICATE A FAILED PROMO CODE OK
            if(this.$('#promo-code').val().length || this.hadValidPromo){
                this.validate();    
            }else {
                this.updatePromoState();
            }            
        },

        updatePromoState: function(state) {
            this.$('#promo-price').empty().hide();
            this.$('#promo-state .state-valid').hide();
            this.$('#promo-state .state-invalid').hide();
            this.$('#promo-state .state-loading').hide();

            // if promo has focus, and we get back invalid don't show it
            if(this.promoHasFocus && state == 'invalid'){
                // DO NOT SHOW ANYTHING OR simply change state to loading
                state = 'loading';
            }else {

            }
            if(state != undefined){
                this.$('#promo-state .state-'+state).css({'display': 'inline-block'});
            }

            // else, because we want the success while we still have focus though son

            

        },

        dirtySubscriptionHandler: function(e){
            this.user_subscription = $(e.currentTarget).is(':checked');
        },

        validate: function(){
            // it's totally possible at this point there is no need to validate anything… because a new square hasn't been input, that's ok, we just send anyhow
            var payload = this.buildPayload();
            var API_ENDPOINT = $(this.$el).attr('data-validation');
            var scope = this;
            this.is_validating = true;
            // do we have a duplicate entry in any children views (aka claiming the same lifesquare for 2 or more patients)
            $.ajax({
                url: API_ENDPOINT,
                type: 'POST',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(payload),
                success: function(data){
                    scope.is_validating = false;
                    scope.validationResponseHandler(data);
                },
                error: function(data){
                    scope.is_validating = false;
                    // it's really not errors, or is it
                }
            });
        },

        validationResponseHandler: function(response){
            // update total
            // number format the display son
            var dollars = response.Total / 100;
            $('#payment-total').val(
                dollars.toLocaleString("en-US", {style:"currency", currency:"USD"})
            );

            if(response.Total > 0){
                $('#payment').show();
                $('#no-payment-info').hide();
                this.requires_payment = true;
                // worrying about restoring subscription preference is not that important, leave it off, aka do nothing
                if(this.user_subscription === true || this.user_subscription == null){
                    $('input[name="subscription"]').prop('checked', 'checked');
                }
            }else {
                $('#payment').hide();
                $('#no-payment-info').show();
                this.requires_payment = false; // don't worry the server will enforce all the things… it's not spoofable
                // zap subscription setting
                $('input[name="subscription"]').removeProp('checked');
            }

            var ship = false;

            // swoop the children views, big ass assumption on ordering… but inner loop to double checks checker
            for(var i=0;i<response.Patients.length;i++){
                // view
                var view = this.pillViews[i];
                var data = response.Patients[i];
                if(data.LifesquareId != null && data.Valid){
                    view.updateState('valid');
                }else if(data.LifesquareId != null && data.Valid === false){
                    view.updateState('invalid');
                    ship = true;
                }else {
                    view.updateState();
                    ship = true;
                }                
            }
            this.requires_shipping = ship;
            if(this.requires_shipping){
                $('#shipping-form').show();
                $('#no-shipping').hide();
            }else{
                $('#shipping-form').hide();
                $('#no-shipping').show();
            }

            if(response.Promo != undefined){
                if(response.Promo.Valid){
                    this.updatePromoState('valid');
                    var dollars = response.Promo.Price / 100;
                    this.$('#promo-price').css({'display': 'inline'}).html('Promotion Applied: ' + dollars.toLocaleString("en-US", {style:"currency", currency:"USD"}) + ' per Lifesquare');
                    this.hadValidPromo = true;
                }else {
                    this.updatePromoState('invalid');
                }
            }else{
                this.updatePromoState();
            }
        },

        stripeResponseHandler: function(status, response){
            // THE ONLY THINGS THAT WILL GENERATE ERRORS AT THIS POINT
            // Are bum card numbers that don't pass the algo checks
            // Legit checking is in the server side and will be handled in the error handler for this.submitToApi
            if (response.error) {
                // Show the errors on the form
                app.alert(response.error.message);
                // this.$el.find('.payment-errors').text(response.error.message);
                // $form.find('button').prop('disabled', false);
                // un fudge our submit button
                this.unlockForm();
            } else {
                // response contains id and card, which contains additional card details
                this.payload.Payment['Token'] = response.id;
                this.submitToApi();
            }            
        },

        submitToApi: function(){
            // TODO: redirect url, should be encoded into dom, but have a fallback
            var API_ENDPOINT = $(this.$el).attr('data-action');
            var scope = this;
            $.ajax({
                url: API_ENDPOINT,
                type: 'POST',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(this.payload),
                success: function(data){
                    try {
                        if(scope.payload.Patients.length == 1){
                            // TODO: handle sending of appropriate notification message (shipped or charged or whatever)
                            window.location = '/profiles/' + scope.payload.Patients[0].PatientId + '/setup-complete';
                            return;
                        }
                    } catch (e){

                    }
                    window.location = '/profiles';
                    return;
                },
                error: function(data){

                    // problem with validation of data
                    if(data.status == 400){
                        app.alert('Invalid Lifesquares (not available or duplicate submissions). Please double check and try again, or choose "I need Lifesquares"');
                    }
                    // problem with payment
                    if(data.status == 402){
                        var bla = JSON.parse(data.responseText);
                        var _errors = [];
                        // BLABLABLABLA
                        for(var i=0;i<bla.errors.length;i++){
                            _errors.push(bla.errors[i].message);
                        }
                        app.alert('There was a problem with your billing information. <strong>' + _errors.join(', ') + '</strong>');
                    }
                    // some catch all cluster bomb
                    if(data.status == 500){
                        app.alert('There was un unexpected error. Please contact support@lifesquare.com for assistance.');
                    }

                    scope.unlockForm();
                }
            });
        },

        buildPayload: function(){
            var scope = this;
            this.collection.reset();

            // whahwhwhwhw hwwh wh whwhwh whwh whwh whwhwhwhwhwh whw hwh wh whw hw wh whahaha hwhwhw ahahah whwhw ahwahwa haw awhahw
            _.each(this.pillViews, function(view) {
                //NOTE: code_exists is inferred on instantiation based on HTML
                if(view.model.get('code_exists') !== true) {
                    var visibleForm = view.$('.sticker-code:visible'),
                        visibleRadio = view.$('input[type=radio]:visible'),
                        selectedRadio = view.$('input[type=radio]:checked'),
                        // patientId = view.$('input[name^=patient_id]'),
                        lifesquare = view.$('[name^=lifesquare_uid]');
                    
                    if (visibleForm.length > 0 || selectedRadio.length > 0) {
                        view.model.set({
                            // sticker_status: selectedRadio.val(),
                            // patient_id: patientId.val()
                        });
                        
                        //Don't require code if you're asking for stickers
                        if(view.model.get('sticker_status') !== '0') {
                            view.model.set('lifesquare_uid', null);
                        }
                        
                        // view.model.validate();
                        //if(!view.model.isValid()) {
                        //    lifesquare.addClass('error');
                        //}
                        
                        scope.collection.add(view.model);
                    } else {
                        visibleRadio.addClass('error');
                        view.$('.no-radio').show();
                    }
                }
            });

            var list = [];
            _.each(this.collection.models, function(model) {
                // GHETTO TO THE MAX SON
                var lsq = null;
                if(model.attributes.lifesquare_uid_formatted != ''){
                    lsq = model.attributes.lifesquare_uid_formatted.split(' ').join('');
                }
                list.push({
                    PatientId: model.attributes.patient_uuid,
                    LifesquareId: lsq
                });
            });

            var subscription = false;
            if($('input[name="subscription"]').length && $('input[name="subscription"]').prop('checked')){
                subscription = true;
            }

            var payload = {
                Patients: list,
                Shipping: {
                    ResidenceId: parseInt($('#mailing-address').val(), 10)
                },
                PromoCode: $('#promo-code').val(),
                Subscription: subscription,
                Payment: {}
            };
            return payload;
        },

        lockForm: function(){
            this.$('button[type="submit"]').text('Submitting...').attr('disabled', 'disabled').addClass('disabled');
            $('#action-transaction-save').text('Submitting...').attr('disabled', 'disabled').addClass('disabled');
        },

        unlockForm: function(){
            this.$('button[type="submit"]').text('Submit').removeProp('disabled').removeClass('disabled');
            $('#action-transaction-save').text('Submit').removeProp('disabled').removeClass('disabled');
        },
        
        submitForm: function(e) {
            e.preventDefault();

            // TODO: STOP and alert on any invalid lifesquares (wrong code, or empty but noted as claiming)
            // THIS IS IMPORTANT

            this.lockForm();
            this.payload = this.buildPayload();

            if(this.requires_payment){
                if($('#existing-card').length && $('#existing-card').val() != ''){
                    this.payload.Payment['CardId'] = $('#existing-card').val();
                    this.submitToApi();
                }else{
                    if($('#s-card-number').val() != '' && $('#s-cvc').val() != '' && $('#s-exp-month').val() != '' && $('#s-exp-year').val() != ''){
                        Stripe.card.createToken($('#payment'), this.stripeResponseHandler);
                    } else {
                        app.alert('Please input payment information.');
                        this.unlockForm();
                    }
                }
            } else {
                this.submitToApi();
            }
        }
    });
    _.extend(Patient.Views.LifesquaresAssign.prototype, Backbone.Session.prototype);
})(app.module('account'), app.module('patient'));
