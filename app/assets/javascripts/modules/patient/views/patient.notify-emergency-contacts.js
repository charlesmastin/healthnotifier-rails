(function (Patient) {
    "use strict";
    Patient.Views.NotifyEmergencyContacts = Patient.Views.Edit.extend({

        // on the initial, add one if we have none, yea son but we have to allow it to be skippable, sucka

        onDone: function(options){
            $.ajax({
                url: options.action,
                type: 'POST',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify({}),
                success: function(data){
                    if(data.redirect_url != undefined){
                        window.location = data.redirect_url;
                    }else {
                        window.location = '/profiles/';
                    }
                },
                error: function(data){
                    app.alert('Error notifying contacts. Please try again or contact support@lifesquare.com for assistance.');
                }
            });
        }
    });
}(app.module('patient')));
