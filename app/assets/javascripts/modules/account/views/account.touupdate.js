(function(Account, undefined) {
    Account.Views.TouUpdate = Backbone.View.extend({
        events: {
            'click button[type="submit"]': 'handleSubmit'
        },

        handleSubmit: function(e){
            if(!$('input[name="reviewed_terms"]').prop('checked')){
                e.preventDefault();
                e.stopImmediatePropagation();
                $('p[data-for="reviewed_terms"]').show();
                return false;
            }
        },
        
        initialize: function() {
            var self = this;
            // bake this into some Vanilla JS somewhere, SON
            self.initializeSession();
            self.on('sessionExpired', function() {
                document.location.href = self.sessionPath;
            }).on('sessionTimeoutWarning', function() {
                if(!self.timeoutView) {
                    self.timeoutView = new Account.Views.TimeoutWarning({ sessionManager: self });
                }
                self.timeoutView.render();
            });
        },
    });
    _.extend(Account.Views.TouUpdate.prototype, Backbone.Session.prototype);
})(app.module('account'));
