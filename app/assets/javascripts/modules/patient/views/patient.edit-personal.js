(function (Patient) {
    "use strict";
    Patient.Views.EditPersonal = Patient.Views.Edit.extend({
        
        onlyOneMailing: function(e) {
            var self = this,
                chosenView = null;
            _.each(self.views, function(view) {
                var viewRadio = view.$('.mailing-address-radio'),
                    selected = false;
                
                if(viewRadio.length > 0) {
                    _.each(viewRadio, function(radio, index) {
                        if(radio === e.target) {
                            selected = true;
                            chosenView = index;
                        }
                        view.collection.models[index].set({mailing_address: false});
                    });
                    view.collection.models[chosenView].set({mailing_address: true});
                }
            });
        },
        
        handleSubmit: function(e) {
            e.preventDefault();
            var self = this,
                welcome;

            // do we have at least 1 address on file up in here son
            // this should really be on the collection level, but for now, we can catch all in here
            // bla we could hack all the things, or we could check the collection and look at 
            var valid_residence = false;
            for(var i=0;i<self.views[2].collection.length;i++){
                var m = self.views[2].collection.at(i);
                if(!m.get('_destroy')){
                    valid_residence = true;
                }
            }
            
            if(!valid_residence){
                app.alert('Please input at least 1 residence!');
                // and scroll yourself there
                $(window).scrollTo($('#residences'));
                return;
            }else{
                
            }

            //First view should be personal, which has patient model
            if(!self.views[0].model.get('patient_id')) {
                welcome = self.views.shift();
                welcome.model.save().done(function() {
                    self.submit(e, $('#action-transaction-save'));
                });
            } else {
                self.submit(e, $('#action-transaction-save'));
            }
        }
        
    });
})(app.module('patient'), app, Backbone, $, _, undefined);
