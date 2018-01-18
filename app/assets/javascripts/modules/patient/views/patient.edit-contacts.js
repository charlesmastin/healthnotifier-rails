(function (Patient) {
    "use strict";
    Patient.Views.EditContacts = Patient.Views.Edit.extend({

        // this is sketchy, but our server-side continue setup flow isn't bullet proof at the moment        
        onDone: function(options){
            // THIS was our ec info logic, ain't no thang son
            /*
            var confirmed = [];
            for(var i=0;i<this.views[0].views.length;i++){
                var model = this.views[0].views[i].model;
                //console.log('isNew', model.isNew());
                //console.log(':changed', model.changedAttributes());
                // model.isNew() || model.changedAttributes() != false || 

                // to correctly detect the changed attributes with this ghetto hook, we have to also hook the validation, lolzor

                if(model.get('list_advise_send_date') == undefined){
                }else{
                    confirmed.push(model);
                }
            }
            */
            // no longer an appropriate logic decision
            /*
            if(confirmed.length == this.views[0].views.length){                
                window.location = options.action_alt;
            }else{
                window.location = options.action;
            }
            */
            // blasters
            window.location = options.action;
        },

        handleSubmit: function(e) {
            e.preventDefault();
            var self = this;
            if(!self.model.get('confirmed') && self.virgin){
                // callback on your steeze for app.confirm son
                app.confirm({
                    title: "Proceed without adding information?",
                    text: "You may enter it later and update at any time but we recommend adding it now.",
                    type: "info",
                    showCancelButton: true,
                    allowOutsideClick: false,
                    confirmButtonText: "Proceed"
                    },
                    function(){
                        self.submit(e, $('#action-transaction-save'));
                    }
                );
            }else {
                self.submit(e, $('#action-transaction-save'));
            }
        }
        
    });
}(app.module('patient')));
