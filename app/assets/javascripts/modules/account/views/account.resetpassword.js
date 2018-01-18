(function(Account, undefined) {
    Account.Views.ResetPassword = Backbone.View.extend({
        events: {
            // 'blur [type=password]': '',
            'click [type=submit]': 'validateForm'
        },
        
        initialize: function() {
            _.bindAll(this, 'validateForm', 'matchPasswords', 'validatePassword');
            this.p1 = this.$el.find('#account_password');
            this.p2 = this.$el.find('#password_confirmation');

            //
            this.p1.focus();
        },

        validateForm: function(e){
            if(this.validatePassword(this.p1) && this.validatePassword(this.p2)){
                if(!this.matchPasswords()){
                    e.stopImmediatePropagation();
                    return false;
                }
            }else{
                e.stopImmediatePropagation();
                return false;
            }
        },
        
        matchPasswords: function() {
            var errors = this.$('.mismatch');
            errors.hide();
            if(this.p1.val().length > 0 && this.p2.val().length > 0 && this.p1.val() !== this.p2.val()) {
                errors.show();
                return false;
            }
            return true;
        },
        
        validatePassword: function(elem) {
            var error = $("[data-for='" + elem.attr('id') + "']");            
            error.hide();
            if(Backbone.Validation.validators.password(elem.val()) !== undefined) {
                error.show();
                elem.focus();
                return false;
            }
            return true;
        }
    });
})(app.module('account'));
