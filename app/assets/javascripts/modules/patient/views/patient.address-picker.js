(function(Patient) {
    "use strict";
    Patient.Views.AddressPicker = Backbone.View.extend({
        events: {
            'change .mailing-address': 'displayAddress'
        },
        
        initialize: function(options) {
            _.bindAll(this, 'displayAddress');
        },
        
        displayAddress: function(e) {
            e.preventDefault();
            
            var selectedIndex = e.target.selectedIndex,
                $address = this.$('#residence_' + selectedIndex);
            
            this.$('.address-label').hide();
            $address.show();
        }
    });
})(app.module('patient'));