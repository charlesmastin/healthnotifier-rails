(function(Account, undefined) {
    Account.Views.Info = Backbone.View.extend({
        events: {
            'blur [type=password]': 'checkPasswords',
            'click [type="submit"]': 'validateForm'
        },
        
        initialize: function() {
            _.bindAll(this, 'checkPasswords', 'matchPasswords', 'validatePassword', 'validateForm', '_validateForm');
            
            var self = this;
            self.initializeSession();
            self.on('sessionExpired', function() {
                document.location.href = self.sessionPath;
            }).on('sessionTimeoutWarning', function() {
                if(!self.timeoutView) {
                    self.timeoutView = new Account.Views.TimeoutWarning({ sessionManager: self });
                }
                self.timeoutView.render();
            });
            
            this.$password = this.$('#account_password');
            this.$password_confirmation = this.$('#password_confirmation');
        },
        
        checkPasswords: function(e) {
            this.validatePassword(e);
            this.matchPasswords(e);
        },
        
        matchPasswords: function(e) {
            var p1 = this.$password.val(),
                p2 = this.$password_confirmation.val(),
                $errors = this.$('.mismatch'),
                $submit = this.$('[type=submit]');
            
            $errors.hide();
            $submit.attr('disabled', null);
            if(p1.length > 0 && p2.length > 0 && p1 !== p2) {
                $errors.show();
                $submit.attr('disabled', true);
            }
        },
        
        validatePassword: function(e) {
            var $target = $(e.target),
                $error = $("[data-for='" + $target.attr('id') + "']"),
                $submit = this.$('[type=submit]');
            
            $error.hide();
            $submit.attr('disabled', null);
            if($target.val().length > 0 && Backbone.Validation.validators.password($target.val()) !== undefined) {
                $error.show();
                $submit.attr('disabled', true);
            }
        },

        validateForm: function(e){            
            var mobile_phone = null;
            // TOP LEVEL VALIDATION SON on clearing mobile phone
            if ($('#account_mobile_phone').val() != ''){
                mobile_phone = $('#account_mobile_phone').val();
            } else {
                var scope = this;
                if(window.ACCOUNT_MOBILE_PHONE != null){
                    app.confirm({
                        title: "Really Remove Mobile Phone?",
                        text: "Account recovery and login will be more time consuming!",
                        type: "error",
                        showCancelButton: true,
                        allowOutsideClick: true,
                        confirmButtonText: "Remove"
                        },
                        function(){
                            scope._validateForm(e);
                        }
                    );
                    return;
                }
            }
            this._validateForm(e);
        },

        _validateForm: function(e){
            var url = $(e.currentTarget).attr('data-url');
            var mobile_phone = null;
            if ($('#account_mobile_phone').val() != ''){
                mobile_phone = $('#account_mobile_phone').val();
            }
            var payload = {
                Email: $('#account_email').val(),
                MobilePhone: mobile_phone
            }

            if($('#account_password').val() != ''){
                if($('#account_current_password').val() != '' && $('#account_password').val() == $('#password_confirmation').val()){
                    // now tap the validators - this code is slop, and not DRY
                    if(Backbone.Validation.validators.password($('#account_password').val()) == undefined){
                        payload['CurrentPassword'] = $('#account_current_password').val();
                        payload['NewPassword'] = $('#account_password').val();
                    } else{
                        e.preventDefault();
                        e.stopImmediatePropagation();
                        app.alert('Please ensure passwords are valid');
                        return false;
                    }
                } else {
                    e.preventDefault();
                    e.stopImmediatePropagation();
                    app.alert('Please fill in all required password fields');
                    return false;
                }
            }

            this.submitForm(url, payload);
        },

        submitForm: function(url, payload){
            // TODO: lock/unlock form
            $.ajax({
                url: url,
                type: 'POST',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(payload),
                success: function(pauload){
                    // redirect yoself, assume server side notification / aka messages
                    window.location = '/account/edit';
                },
                error: function(data){
                    var responseJson = JSON.parse(data.responseText);
                    if(data.status == 400){
                        app.alert('Error: ' + responseJson.message);
                    }
                    if(data.status == 500){
                        app.alert('Error: Something Broke, we\'re on it!');
                    }
                }
            });
        }
        
    });
    _.extend(Account.Views.Info.prototype, Backbone.Session.prototype);
})(app.module('account'));
