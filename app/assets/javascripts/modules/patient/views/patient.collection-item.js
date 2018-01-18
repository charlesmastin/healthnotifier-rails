(function (Patient) {
    "use strict";
    Patient.Views.CollectionItem = Backbone.View.extend({
        
        tagName: 'div',
        className: 'item',
        
        defaults: {
        },
        
        events: {
            'click .destroy': 'clear', // misleading as ever        
            'keypress .condition-name': 'updateOnEnter', // move to subclass
            'keypress input': 'preventSubmit',
            'blur input': 'saveInputValue',
            'blur select': 'saveInputValue',
            'change input': 'saveInputValue',
            'change select': 'saveInputValue',
            'click [type=checkbox]': 'saveInputValue'
        },
        
        initialize: function(options) {
            this.options = options;
            _.bindAll(this, 'render', 'close', 'edit', 'updateOnEnter', 'preventSubmit', 'remove', 'clear',
                'toggleItemEditor', 'handleModelError', 'saveInputValue', 'saveFormState');
            
            var self = this;
            
            //Set rules as fields are encountered. WARNING: This is weird, I know.
            self.validationRules = self.model.validation;
            self.model.validation = {};
            
            Backbone.Validation.bind(this, {
                forceUpdate: true,
                selector: 'name',
                valid: function (view, attr) {
                    // $('#' + attr).removeClass('error');
                    var field = view.$('[name="' + attr + '"]');
                    field.removeClass('error');
                    $("[data-for='" + field.attr('id') + "']").hide();
                    // view.$('[name="' + attr + '"]').siblings('.error-message').hide();
                },
                invalid: function(view, attr, error) {
                    // $('#' + attr).addClass('error');
                    var field = view.$('[name="' + attr + '"]');
                    field.addClass('error');
                    $("[data-for='" + field.attr('id') + "']").show();
                    // view.$('[name="' + attr + '"]').siblings('.error-message').show();
                }
            });

            this.model.on('change', function(model, options){
                // oh bla
                //console.log('model changed');
                // blablablabalbal
                $(document).trigger('onPatientChange');
            });
            
            this.model.on('validated', function(isValid, model, attrs) {
                if (isValid) {
                    self.$('.error-message').hide();
                }
            });
            // this.model.on('error', this.showError);
        },
        
        render: function() {
            this.$el.html(this.options.template(this.model.toJSON()));          
            return this;
        },
        
        close: function() {
            
        },
        
        edit: function() {
            
        },
        
        // move to subclass
        updateOnEnter: function(e) {
            if (e.keyCode == 13) this.close();
        },
        
        preventSubmit: function(e) {
            if (e.keyCode === 13) {
                e.preventDefault();
                e.stopPropagation();
            }
        },
        
        remove: function() {
            this.$el.remove();
            this.model.set('_destroy', true);
            this.model.validation = {};
            this.validationRules = {};
            //HACK: Yes, this stinks.
            this.model.validate = function() { return true; };
            this.model.isValid = function() {return true; };

            // this is no more way to access the container collection and "remove" the new model, but it should work out anyhow

        },
        
        clear: function(e) {
            //
            console.log('patient.collection-item.clear');
            console.log(this.model.isEmpty())
            console.log(this.model.isNew())
            if(e) e.preventDefault();
            var scope = this;
            
            if(this.model.isEmpty() === true){
                this.remove();
                console.log('we removed it');
                return;
            }

            app.confirm({
                title: "Really Remove?",
                text: "Item will not be deleted until you Save Changes",
                type: "error",
                showCancelButton: true,
                allowOutsideClick: true,
                confirmButtonText: "Remove"
                },
                function(){
                    scope.remove();
                }
            );
        },
        
        toggleItemEditor: function(e) {
            var target = e.target,
                $container = $('#' + $(target).data('container')),
                $entries = $('.entries', $container);

            $entries.toggle(!!~~e.target.value);
        },
        
        handleModelError: function(view, errorMessages, options) {
            var self = this;
            _.each(errorMessages, function(field) {
                self.showError(field);
            });
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
            var values = {};
            _.each($('input:visible, select', this.$el), function(el) {
                values[el.name] = (el.type != 'checkbox') ? el.value : el.checked;
            });
            this.model.validation = this.validationRules;
            this.model.set(values);
        }
    });
}(app.module('patient')));
