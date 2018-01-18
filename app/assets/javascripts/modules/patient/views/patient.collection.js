(function (Patient, Medication) {
    "use strict";
    Patient.Views.Collection = Backbone.View.extend({
        events: {
            'click a.create': 'create',
            'click .display': 'toggleItemEditor',
            'click a.privacy-control': 'showPrivacyMenu'
        },

        // not true OO, so let's bring these back
        count: 0,
        views: [],

        initialize: function(options) {
            this.options = options;

            _.bindAll(this, 'showPrivacyMenu', 'setPrivacy', 'resetCount', 'reveal', 'showSelectValue', 'addAutocomplete', 'search',
                'toggleDisplayButtons', 'toggleItemEditor', 'destroyCollection', 'render',
                'addOne', 'addAll', 'saveCollection', 'preSave', 'saveFormState', 'create', 'isValid', 'showBannerError');


            this.count = 0;

            // this.collection.bind('add', this.addOne, this);
            this.collection.bind('reset', this.render, this);
            // this.collection.bind('all', this.render, this);

            // this.collection.on('add', this.toggleDisplayButtons);
            // this.collection.on('remove', this.toggleDisplayButtons);
            this.collection.on('update', function(collection, options){
                // toss that bad boy up the chain into generic spacetime
                $(document).trigger('onPatientChange', collection);
            });

            this.collection.on('reset', this.resetCount);

            if(this.collection.url && this.collection.models.length === 0) {
                //TODO: Re-enable when we know we want this.
                // this.collection.fetch();
            }

            if(!this.options.delayRender || this.collection.length > 0) {
                this.render();
            }

            // Show the Add buttons
            $('.display').each(function(index) {
                if (this.checked && !!~~this.value) {
                    var $container = $('#' + $(this).data('container'));
                    var $entries = $('.entries', $container);
                    $entries.toggle(true);
                }
            });

            //$(document).off('popover.hide', this.popStop);
            //$(document).on('popover.hide', this.popStop);
        },
        /*
        popStop: function(e, id){
            alert('DONKEY NUTS');
            // e.stopImmediatePropagation();
            // meh this is so wrong, attempt to undelegate the popover handler, oh boy, dirty as dog doo on your shoes
            var pop = $('#popover-privacy-control');
            if(pop){
                pop.off('click');// lol son lol
            }
        },
        */

        showPrivacyMenu: function(e){
            var scope = this;
            e.preventDefault();
            // calculate index? is that safe? hmmm maybe?
            var index = $(e.currentTarget).parents('div.item').index();

            var pop = popover.show(e, $(e.currentTarget).attr('data-popover'));
            pop.on('click', 'a.privacy', function(e){
                scope.setPrivacy(index, $(e.currentTarget).attr('data-privacy'));
                pop.off('click'); // meh, cheap town
                // ghetto blast times here
                popover.hide('privacy-control');
                return false;
            });
            // we could a- listen to that dom element
            // then detach upon hearing the popover hidden biziness
            return false;
        },

        setPrivacy: function(index, privacy){
            this.views[index].model.set('privacy', privacy);
            // this is quite possibly the most hackterrific code I know, well par for da course son
            // update the privacy icon
            // update the classes on the i
            // FML SON, but this is WAY easier than trying out react
            var icon = this.views[index].$el.find('.component.privacy-control i');
            // privacy options conditional duplication 1000
            icon.removeClass().addClass('material-icons').addClass('privacy-'+privacy);
            switch(privacy){
                case 'public':
                    icon.text('people');
                break;
                case 'provider':
                    icon.text('verified_user');
                break;
                case 'private':
                    icon.text('lock');
                break;
            }
            
            //
            // where is the two way binding on the biziness… ug, we just want to re-render the subview, lol failzones
            // this.views[index].render();
        },

        resetCount: function() {
            this.count = 0;
            console.log('change town, don\'t go breaking it all');
            $(document).trigger('onPatientChange', this.collection);
        },

        reveal: function(e) {
            e.preventDefault();
        },

        showSelectValue: function(e) {
            var $target = $(e.target),
                selectedIndex = e.target.selectedIndex;
                $option = $('option', $target).get(selectedIndex),
                $customView = $('span span', $target.next());

            $customView.html($option.html());
            $option.attr('selected', true);
        },

        addAutocomplete: function($el, category, cb) {
            var self = this;
            $el.autocomplete({
                source: function(request, requestCallback) {
                    function callback(data) {
                        if (cb) {
                            cb(data, requestCallback);
                        } else {
                            requestCallback(data.items);
                        }
                    }
                    self.search(category, request.term, callback);
                },
                delay: 300,
                // disable those pesky hover bits on uh, mobile browsers (lolzors)
                open: function(event, ui) {
                    $('.ui-autocomplete').off('menufocus hover mouseover mouseenter');
                }
            });

            $el.on('focus', function(){
                $el.autocomplete('option', 'disabled', false);
            }).on('blur', function() {
                if ($('ul.ui-autocomplete:visible').length === 0) {
                    $el.autocomplete('option', 'disabled', true);
                    $el.removeClass('ui-autocomplete-loading');
                }
            });

            return $el;
        },

        search: function(category, term, callback) {
            $.ajax('/api/v1/term-lookup/search', {
                data: {
                    category: category,
                    term: term,
                },
                dataType: 'json',
                success: function(data, textStatus, jqXHR) {
                    callback(data);
                },
                error: function(jqXHR, textStatus, errorThrown) {
                    console.log('error: ' + textStatus, jqXHR, errorThrown);
                },
            });
        },

        toggleDisplayButtons: function(e) {
            var $radios = this.$('input[type=radio]'),
                $show = $radios.first(),
                $hide = $radios.last();

            if (this.collection.length > 0) {
                $show.click();
            } else {
                $hide.click();
            }
        },

        toggleItemEditor: function(e) {
            // legacy method for when we have the postive negative bit in there
            var target = e.target,
                $container = $('#' + $(target).data('container')),
                $entries = $('.entries', $container),
                reveal = !!~~e.target.value;

            if (reveal){
                this.$el.find('.create').css({'display': 'inline-block'});
                if($('.item', $entries).length == 0){
                    this.addOne(new this.collection.model);
                }
            } else {
                this.$el.find('.create').css({'display': 'none'});
            }

            if (!reveal && $('.item', $entries).length > 0) {
                app.confirm(
                    {
                        title: "Really Delete?",
                        text: app.messages.WARNING_DELETE_ALL_ENTRIES,
                        type: "error",
                        showCancelButton: true,
                        confirmButtonText: "Delete"
                    },
                    function(){
                        this.destroyCollection();
                    }
                );

                e.preventDefault();
                e.stopPropagation();
                return;
            }

            $entries.toggle(reveal);
        },

        destroyCollection: function() {
            _.each(this.views, function(view) {
                view.remove();
            });
        },

        render: function() {
            var self = this;
            /*
            try {
                _.each(this.views, function(view,index) {
                    view.remove();
                    delete self.views[index];
                });
            } catch(e) {
                console.log('error removing previous view from implementing class');
            }
            */
            if(self.collection.length > 0) {
                self.addAll();
            }
        },

        addOne: function() {},

        addAll: function() {
            this.collection.each(this.addOne);
        },

        saveCollection: function() {
            var self = this,
                list = [];
            _.each(self.views, function(view) {
                console.log(view);
                list.push(view.model.toJSON());
            });

            var req_object = {};
            req_object[self.collection.collection_name] = list;

            self.preSave(req_object);

            var request = $.ajax({
                url: self.collection.url(),
                type: 'POST',
                dataType: 'json',
                data: JSON.stringify(req_object),
                contentType: 'application/json'
            });

            return request;
        },

        preSave: function(req_object) {
        },

        saveFormState: function() {
            var self = this;
            // TODO: potential bigtime cluster
            _.each(self.views, function(view) {
                view.saveFormState();
            });
        },

        create: function(e) {
            e.preventDefault();
            this.addOne(new this.collection.model);
            return false;
        },

        isValid: function() {
            var childFormsValid = true;
            _.each(this.views, function(child) {
                child.model.validate();
                if(childFormsValid === true && child.model.isValid() === false) {
                    childFormsValid = false;
                }
            });

            return childFormsValid;
        },

        showBannerError: function(errMsg) {
            window.app.showFlashMessage(errMsg, 'error', true);
        }
    });
}(app.module('patient'), app.module('medication')));
