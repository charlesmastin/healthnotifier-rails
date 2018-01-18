(function (Patient) {
    "use strict";
    Patient.Views.Index = Backbone.View.extend({
        events: {
            'click article': 'viewPatient', 
        },

        initialize: function() {
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
        },

        passThroughLink: function(e){
            e.preventDefault();
            e.stopImmediatePropagation();
            document.location = $(e.target).attr('href');
        },

        createPatient: function(e) {
            e.preventDefault();
            document.location.href = '/profiles/new';
        },

        viewPatient: function(e) {
            if($(e.target).get(0).tagName == "A"){
                e.stopImmediatePropagation();
            }else {
                document.location.href = $(e.currentTarget).data("detail-url");
            }
        }
    });
    _.extend(Patient.Views.Index.prototype, Backbone.Session.prototype);
})(app.module('patient'));
