(function(Organization) {
    "use strict";

    Organization.Views.RenewLifesquares = Backbone.View.extend({
        events: {
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

            // 
            scope.results = [];

            _.bindAll(this, 'updateFeeDisplay', 'addAutocomplete', 'searchNetwork', 'renderResultNode', 'addResult',
                'submitForm', 'lockForm', 'unlockForm', 'submitToApi', 'stripeResponseHandler');

            scope.addAutocomplete($('#member_uuid'), function(data, cb) {
                var items = _.map(data.results, function(item) {
                  return {
                    label: item.profile.first_name + " " + item.profile.last_name,
                    value: undefined,
                    result :item // namespaced so we can swap back to a standard renderer bro bas
                  };
                });
                cb(items);
            });

            $(document).off('click', '.remove-member');
            $(document).on('click', '.remove-member', function(e){
                scope.removeResult($(e.currentTarget).attr('data-uuid'));
            });
        },

        removeResult: function(uuid){
            var scope = this;
            // remove via patient uuid
            // yea, it's basically gauranteed to be in the array
            var index = -1;
            for(var i=0;i<scope.results.length;i++){
                if(scope.results[i].result.profile.uuid == uuid){
                    index = i;
                    break;
                }
            }
            if(index != -1){
                $('#exclusion-list li[data-uuid="' + uuid + '"]').remove();
                scope.results.splice(i, 1);
                scope.updateFeeDisplay();
            }
        },

        renderResultNode: function(item){
            var content = '<article class="profile-search-result">';
            // profile pic bro
            //if(item.result.profile.photo_uuid){
                content += '<article class="user-thumbnail-circle medium">';
                content += '<p class="user-thumbnail">';
                content += '<img src="/api/v1/profiles/' + item.result.profile.uuid + '/profile-photo?width=128&amp;height=128&uuid=' + item.result.profile.photo_uuid + '" alt="Profile Pic">';
                content += '</p>';
                content +=  '</article>';
            //}
            // Name
            content += '<article class="details">';
            content += '<h4>' + item.result.profile.fullname + '</h4>';

            // email
            content += '<small class="email">' + item.result.account.email + '</small>';

            // provider status
            if(item.result.account.provider){
                content += '<span class="tag provider-account"><i class="material-icons">verified_user</i>Health care provider</span>';
            }

            content += '</article>';

            content += '</article>';
            // TODO: cast into a DOM element now? or later
            return content;
        },

        addResult: function(item){
            var scope = this;
            // if it doesn't exist
            var found = false;
            // about 100 different ways to iterate, can't remember the best
            for(var index in scope.results){
                if(scope.results[index].result.profile.uuid == item.result.profile.uuid){
                    found = true;
                    break;
                }
            }
            if(found){
                window.app.alert("Duplicate Profile Found!");
            }else {
                scope.results.push(item);
                $("#exclusion-list").append('<li data-uuid="' + item.result.profile.uuid + '">' + scope.renderResultNode(item) + '<div><a data-uuid="' + item.result.profile.uuid + '" href="#" class="button remove-member">Remove</a></div></li>');
                scope.updateFeeDisplay();
            }
        },

        addAutocomplete: function($el, cb) {
            var scope = this;
            // var self = this;
            $el.autocomplete({
                source: function(request, requestCallback) {
                    function callback(data) {
                        if (cb) {
                            cb(data, requestCallback);
                        } else {
                            requestCallback(data.items);
                        }
                    }
                    scope.searchNetwork(request.term, callback);
                },
                // http://stackoverflow.com/questions/16371204/how-to-change-rendering-of-dropdown-in-jquery-ui-autocomplete-attached-to-a-clas
                create: function () {
                    $(this).data('ui-autocomplete')._renderItem = function (ul, item) {
                        // build dat node bizzle nozzle nuts
                        
                        return $('<li>')
                            .append(scope.renderResultNode(item))
                            .appendTo(ul);
                    };
                },
                
                delay: 300,
                // disable those pesky hover bits on uh, mobile browsers (lolzors)
                open: function(event, ui) {
                    $('.ui-autocomplete').off('menufocus hover mouseover mouseenter');
                }
            });

            $el.on('focus', function(){
                $el.autocomplete('option', 'disabled', false);
            }).on('blur', function() {
                if ($('ul.ui-autocomplete:visible').length === 0) {
                    // $el.autocomplete('option', 'disabled', true);
                    $el.removeClass('ui-autocomplete-loading');
                }
            });

            $el.on('autocompleteselect', function(event, ui) {
                // event.target.disabled = true;
                $("#member_result").empty();
                

                scope.addResult(ui.item);
                //

                setTimeout(function(){
                    $("#member_uuid").val('');
                    // console.log("wipe it down??")
                }, 30);
                
                
            });

            return $el;
        },

        searchNetwork: function(keywords, callback) {
            $.ajax('/api/v1/orgs/'+ window.ORGANIZATION_UUID + '/search/', {
                data: {
                    keywords: keywords,
                },
                dataType: 'json',
                success: function(data, textStatus, jqXHR) {
                    callback(data);
                },
                error: function(jqXHR, textStatus, errorThrown) {
                    console.log('error: ' + textStatus, jqXHR, errorThrown);
                },
            });
        },

        toggleBillingInput: function(e){
            if($(e.target).val() == ''){
                $('#stripe-card-fields-container').removeClass('hidden');
            }else{
                $('#stripe-card-fields-container').addClass('hidden');
            }
        },

        updateFeeDisplay: function(){
            var scope = this;
            var quantity = window.ORGANIZATION_TOTAL_MEMBER_COUNT - scope.results.length;
            var dollars = (quantity * window.ORGANIZATION_UNIT_COST) / 100;
            $('#membership-count').text(quantity);
            $('#payment-total').val(
                dollars.toLocaleString("en-US", {style:"currency", currency:"USD"})
            );
            $('#total').text(
                dollars.toLocaleString("en-US", {style:"currency", currency:"USD"})
            );
        },

        submitForm: function(e){
            // wipe our request cleaners
            var scope = this;

            scope.payload = {
                Exclusions: [],
                Payment: {}
            }
            
            for(var i=0;i<scope.results.length;i++){
                scope.payload.Exclusions.push(scope.results[i].result.profile.uuid);
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
            this.lockForm();
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
                    window.location = window.SUCCESS_URL;//$('#payment-form').attr('data-redirect-url');
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
    _.extend(Organization.Views.RenewLifesquares.prototype, Backbone.Session.prototype);
})(app.module('organization'));      