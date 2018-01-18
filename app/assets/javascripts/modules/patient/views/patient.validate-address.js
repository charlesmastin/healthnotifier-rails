(function (Patient, Utilities) {
    "use strict";

    Patient.Views.ValidateAddress = Backbone.View.extend({
        
        events: {
            'click .action-ok': 'actionSave',
            'click .action-cancel': 'actionCancel',

            // on change, enable the thingy
            'change input[name="address"]': 'handleChange',
        },

        initialize: function(options) {
            this.options = options;

            _.bindAll(this, 'actionSave', 'actionCancel', 'handleChange');
            // ghetto view hacking, really really really really really not worried here
            var r = '';


            // max 3 results and then the intiail one
            for(var i=0;i<3;i++){
                if(this.options.results[i] != undefined){
                    r += '<div class="field"><label><input type="radio" name="address" value="' + i + '" /> ' + this.options.results[i].data.formatted_address + '</label></div>';
                }
            }
            // r += '<hr />';
            r += '<div class="field default"><label><input type="radio" name="address" value="-1" /> ' + this.options.address + '</label><small>Unconfirmable address you have entered</small></div>';

            this.$el.find('.options').empty().append(r);


            // rebind events son
        },

        handleChange: function(e){
            this.$el.find('a.action-ok').removeClass('disabled').removeAttr('disabled');
        },

        pluckPropertyFromResult: function(address, property){
            //
            for(var i=0;i<address.data.address_components.length;i++){
                if(address.data.address_components[i].types[0] == property){
                    return address.data.address_components[i];
                    break;
                }
            }
            // sad trombone
            return {
                short_name: '',
                long_name: ''
            }
        },

        actionSave: function(e){
            // update the model, "hope" the underlying view updates? // meh, it probably won't so we'll need to just send a message that can be consumed, so TEDIOUS
            // what is the value
            var v = this.$el.find('input[name=address]:radio:checked').val();
            if(v != -1){
                var address = this.options.results[v];
                
                // do some updating
                // TODO: use code to actually find the nested attributes, vs just cheaply going into the positional bits since presumably those are going to differ based on the available information
                var number = this.pluckPropertyFromResult(address, 'street_number');
                var route = this.pluckPropertyFromResult(address, 'route');
                this.model.set('address_line1', number.short_name + ' ' + route.short_name);
                // TODO: address line 2, just let it be
                this.model.set('city', this.pluckPropertyFromResult(address, 'locality').long_name);
                this.model.set('state_province', this.pluckPropertyFromResult(address, 'administrative_area_level_1').short_name);
                this.model.set('postal_code', this.pluckPropertyFromResult(address, 'postal_code').short_name);
                this.model.set('_validated', true); // use a hook for the onchange of validated property, to kick off a partial re-render???
                this.model.set('_validation_override', false);
            }else {
                this.model.set('_validation_override', true);
                // but what if we change it again, lol nuts
            }
            // set the validated state, to avoid future validations? no meh? this is tricky and annoying
            $('#address-validator').trigger('reveal:close');
            setTimeout(function(){
                $(window).scrollTo($('#residences'));
            },250);

        },

        actionCancel: function(e){
            $('#address-validator').trigger('reveal:close');
            // toss away the view, throw away the memories, lost forever…
        }

    });

}(app.module('patient'), app.module('utilities')));