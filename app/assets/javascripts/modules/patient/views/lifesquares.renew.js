(function(Account, Patient) {
    "use strict";

    Patient.Views.LifesquaresRenew = Backbone.View.extend({
        events: {
            // submit when this is "account scope" or more than 1 patient
            'click [type="submit"]': 'submitForm',
            'click .cards > article': 'toggleCard',
            'change input.renewal': 'updateFeeDisplay',
            'change #existing-card': 'toggleBillingInput'
        },
        
        initialize: function(options) {
            // external submit button wire down town usa central timezone blowouts
            // event from outside
            var scope = this;
            $(document).off('click', '#action-transaction-save');
            $(document).on('click', '#action-transaction-save', function(e){
                e.stopImmediatePropagation();
                if($(e.currentTarget).hasClass('disabled')){
                    return false;
                }
                scope.submitForm(e);
                return false;
            });

            _.bindAll(this, 'submitForm', 'lockForm', 'unlockForm', 'submitToApi', 'stripeResponseHandler');
        },

        toggleBillingInput: function(e){
            if($(e.target).val() == ''){
                $('#stripe-card-fields-container').removeClass('hidden');
            }else{
                $('#stripe-card-fields-container').addClass('hidden');
            }
        },

        toggleCard: function(e){
            if(e.target.tagName == 'INPUT'){
                return;
            }
            var elem = $(e.target).parents('article');
            var input = elem.find('input');
            if(elem.find('input:checked').length){
                input.removeAttr('checked');
            } else {
                input.prop('checked', true);
            }
            input.trigger('change');
        },

        updateFeeDisplay: function(){
            var cents = 0;
            $('.renewal:checked()').each(function(index, elem){
                cents += parseInt($(this).parents('article').attr('data-coverage-cost'), 10);
            });
            var dollars = cents / 100;
            $('#payment-total').val(
                dollars.toLocaleString("en-US", {style:"currency", currency:"USD"})
            );
        },

        submitForm: function(e){
            // wipe our request cleaners
            var scope = this;

            scope.payload = {
                Patients: [],
                Shipping: {
                    ResidenceId: parseInt($('#mailing-address').val(), 10)
                },
                Payment: {}
            }
            // scoop the patients

            $('.renewal:checked()').each(function(index, elem){
                scope.payload.Patients.push({
                    PatientId: $(elem).attr('data-patient-uuid')
                });
            });

            // do we have at least one patient
            if(scope.payload.Patients.length == 0){
                app.alert('Please select at least one profile!');
                return;
            }

            // pre-validate son don hon
            if($('#payment').length){
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
            }else{
                this.submitToApi();
            }
        },

        submitToApi: function(){
            var API_ENDPOINT = $(this.$el).attr('data-action');
            var scope = this;
            $.ajax({
                url: API_ENDPOINT,
                type: 'POST',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(this.payload),
                success: function(data){
                    // redirect to the confirm screen son, bla bla bla
                    window.location = '/profiles';//$('#payment-form').attr('data-redirect-url');
                },
                error: function(data){

                    // problem with validation of data
                    if(data.status == 400){
                        app.alert('Invalid Lifesquares');
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

        lockForm: function(){
            this.$('button[type="submit"]').text('Submitting...').attr('disabled', 'disabled').addClass('disabled');
            $('#action-transaction-save').text('Submitting...').attr('disabled', 'disabled').addClass('disabled');
        },

        unlockForm: function(){
            this.$('button[type="submit"]').text('Submit').removeProp('disabled').removeClass('disabled');
            $('#action-transaction-save').text('Submit').removeProp('disabled').removeClass('disabled');
        }
    });
    _.extend(Patient.Views.LifesquaresRenew.prototype, Backbone.Session.prototype);
})(app.module('account'), app.module('patient'));      