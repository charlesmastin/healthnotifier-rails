(function (Account) {
    "use strict";
    Account.Views.Create = Backbone.View.extend({
        defaults: {
        },

        events: {
            'click [type=submit]': 'handleSubmit',
            'blur input': 'saveInputValue',
            'click [type=checkbox]': 'saveInputValue',
            'keyup #create_email': 'suggestEmailHost',
            'keyup #create_dob': 'handleDobUp',
            'keypress #create_dob': 'handleDobDown',
            'click .correct-email': 'fixEmail'
        },

        initialize: function() {
            _.bindAll(this, 'render', 'reset', 'suggestEmailHost',
                'fixEmail', 'handleModelError', 'showError', 'handleBlur', 'validateField', 'saveInputValue',
                'saveFormState', 'handleSubmit', 'handleDobUp', 'handleDobDown');

            var self = this;

            //Set rules as fields are encountered. WARNING: This is weird, I know.
            self.validationRules = self.model.validation;
            self.model.validation = {};

            Backbone.Validation.bind(this, {
                forceUpdate: true,
                selector: 'name',
                valid: function (view, attr) {
                    var field = view.$('[name="' + attr + '"]').not('[type=hidden]');
                    field.removeClass('error');
                    $("[data-for='" + field.attr('id') + "']").hide();
                },
                invalid: function(view, attr, error) {
                    var field = view.$('[name="' + attr + '"]').not('[type=hidden]');
                    field.addClass('error');
                    $("[data-for='" + field.attr('id') + "']").show();
                }
            });

            this.model.on('validated', function(isValid, model, attrs) {
                if (isValid) {
                    self.$('.error-message').hide();
                }
            });
            this.render();
        },

        render: function() {
            this.reset();
            var e = qs('email');
            // TODO: hook a core validator for thoroughness, but we kinda trust it
            if(e && e.length > 6){
                self.$('#create_email').val(e);
            }

            // visual focus on email_field
            $('#create_first_name').focus();
        },

        reset: function() {
            var self = this;

            self.model.validation = {};
            self.$('#signup_info').show();
            self.$('input.error').removeClass('error');
            self.$('.error-message').hide();
            // $('form').get(0).reset();
            self.$('button[type="submit"]').text('Submit').removeAttr('disabled').removeClass('disabled');
            //Move off to avoid library unbinding overriding this
            setTimeout(function () {
                self.$el.on('reveal:close', function() {
                    self.reset();
                });
            }, 100);
        },

        handleDobDown: function(e){
            window.app.handleDobDown(e);
        },

        handleDobUp: function(e){
            window.app.handleDobUp(e);
        },

        suggestEmailHost: function(e) {
            var commonHosts = [
                'gmail',
                'yahoo',
                'hotmail',
                'msn',
                'shortmail',
                'me'
            ];

            var $err = this.$('.bad-email-host'),
                address = e.target.value,
                badHost = address.match(/(.*)@(.*?)\.(.*)/i);

            $err.text('').hide();
            if(badHost !== null) {
                _.each(commonHosts, function(host) {
                    var charDiff = badHost[2].levenshtein(host);
                    if(charDiff > 0 && charDiff < 3 ) {
                        $err.html('Did you mean <a href="#" class="correct-email">' + badHost[1] + '@' + host + '.' + badHost[3] + '</a>?').show();
                    }
                });
            }
        },

        fixEmail: function(e) {
            e.preventDefault();
            var $target = $(e.target);

            this.$("#create_email").val($target.text());
            $target.parent().html('').hide();
        },

        handleModelError: function(view, errorMessages, options) {
            var self = this;
            _.each(errorMessages, function(field) {
                self.showError(field);
            })
        },

        showError: function(el) {
            var errorMessage = $(el).parent().find('.error-message');
            if(errorMessage[0]) {
                errorMessage.addClass('present-error-message').show();
            }
        },

        handleBlur: function(e) {
        },

        validateField: function(el) {
            $(el).parent().find('.error-message').removeClass('present-error-message').hide();

            var id = el.id,
                value = el.value;

            //NOTE: This very well may suck. Look at all this tight coupling…
            var dataField = $(el).data('field');
            if(dataField)
                this.model.attributes[dataField] = value;

            var dataValidation = $(el).data('validation'),
                validationType = (dataValidation) ? dataValidation : false
            if(validationType && !this.model[validationType](value)) {
                this.showError(el);
            }
        },

        saveInputValue: function(e) {
            var target = e.target,
                type = target.type,
                id = target.name,
                //NOTE: Not very robust. Needs better betterness.
                value = (type != 'checkbox') ? target.value : target.checked;

            if (this.validationRules[id]) {
                this.model.validation[id] = this.validationRules[id];
            }

            this.model.set(id, value);
        },

        saveFormState: function() {
            var self = this,
                values = {};
            _.each(self.$('input:visible, select'), function(el) {
                if(el.type !== 'submit')
                    values[el.name] = (el.type != 'checkbox') ? el.value : el.checked;
            });
            this.model.validation = this.validationRules;
            this.model.set(values);
        },

        loginUser: function(email, password){
            // hmm how is this gonna work little son, really though, like, how would we write to our "rails cookie" from js???
            // probably answered 100000+ times on Stack Overflizzle
            // for now, punt oun your sheeze
        },

        handleSubmit: function(e) {

            var self = this;
            $('.error-message').hide();
            this.saveFormState();
            this.model.validate();

            //TODO: Clean up this messiness
            if(this.model.isValid() === false) {
                e.preventDefault();
                return false;
            }

            // our model is old and crusty, we need to format it for our API endpoint
            var mobile_phone_e164 = null;
            var mobile_phone = this.model.get('mobile_phone');
            if(mobile_phone != ''){
                // even though we scrub it down with twilio, let's give it a college try here                
                mobile_phone = mobile_phone.match(/\d+/g).join([]);
                mobile_phone_e164 = $("#create_mobile_phone_country").val() + mobile_phone;
            }
            var data = {
                FirstName: this.model.get('first_name'),
                LastName: this.model.get('last_name'),
                Email: this.model.get('email'),
                Password: this.model.get('password'),
                DOB: this.model.get('dob'),
                MobilePhone: mobile_phone_e164
                // meh passing in platform is silly beans we can easily and more accurately determine this on the server
            }

            $(e.target).text('Signing up...').attr('disabled', true);
            var API_ENDPOINT = this.$el.attr('data-api-endpoint');

            var scope = this;
            var email = data.Email;
            
            $.ajax({
                url: API_ENDPOINT,
                type: 'POST',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(data),
                success: function(data){
                    // let's do a client side login submission, since we have your password on "file" aka in memory
                    // scope.loginUser(data.Email, data.Password);
                    // window.location = '/login?email='+encodeURIComponent(email);
                    // TODO: server is client agnostic, so this is one of our rare raw url creations
                    window.location = '/profiles/' + data.patient_id + '/continue-setup';
                },
                error: function(data){
                    // why do I have to do this in 2017???
                    var responseJson = JSON.parse(data.responseText);

                    if(data.status == 400){
                        app.alert('Error: ' + responseJson.message);
                    }
                    if(data.status == 404){
                        app.alert('Error: Email Already Exists');
                    }
                    if(data.status == 500){
                        app.alert('Error: Unknown Error');
                    }
                    scope.reset();
                }
            });
        }
        
    });
}(app.module('account')));
