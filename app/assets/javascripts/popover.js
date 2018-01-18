// this is currently a jquery "plugin" #fail
popover = {
    init: function(elems){
        // run through the dom, decorate all the data-popover elements, lul
        if(elems == undefined || elems.length == 0){
            var elements = $('a[data-popover]');
        }else {
            var elements = elems;
        }
        var scope = this;
        elements.each(function(index, item){
            // TODO: hmm nuggets
            $(item).on('click', function(e){
                e.preventDefault();
                // e.stopImmediatePropagation(); // not always a good idea
                scope.show(e, $(this).attr('data-popover'));
                return false;
            });
        });
    },
    show: function(triggerEvent, id){
        // toggle and return if this is open already
        var scope = this;
        var elem = $('#popover-'+id);
        /*
        if(elem && elem.hasClass('visible')){
            console.log('popover hiding, might be a bug');
            this.hide(id);
            return false;
        }
        */

        // close any existing open popovers, ghetto times usa
        this.hideAll();
        
        // mop up their event handlers son

        // setup the document click off event

        // actually show the element
        if(elem){
            // for now, all popovers position "down"
            var triggerPosition = $(triggerEvent.currentTarget).offset();
            var tX = Math.round(triggerPosition.left);
            var tY = Math.round(triggerPosition.top);

            // apply sweet manual offsets from the popover itself, to get around box model of original event, lol
            if(parseInt(elem.attr('data-offset-x'), 10)){
                tX += parseInt(elem.attr('data-offset-x'), 10);
            }
            if(parseInt(elem.attr('data-offset-y'), 10)){
                tY += parseInt(elem.attr('data-offset-y'), 10);
            }

            var popW = elem.outerWidth();
            var popH = elem.outerHeight();
            // the margins on the "body" we care about - rems to px here
            var margin = 16; // 1rem

            // do default positioning adjust only if necessary, default is centered below
            var posX = tX - (popW / 2);
            var posY = tY + margin;

            // left
            if((tX - popW/2) < (margin * 3)){
                posX = margin;
            }
            // right
            if((tX + popW/2) > ($(window).width() - (margin * 3))){
                // hacking the box - model with the triple margin?
                posX = $(window).width() - (margin * 3) - popW;
            }
            
            var yDeltaBottom = $(window).height() - ($(triggerEvent.currentTarget).offset().top - $(document).scrollTop());
            if((yDeltaBottom < (popH + (margin * 1)))){
                posY = tY - (popH + (margin * 1));
            }
            elem.css({'left': posX, 'top': posY});
            elem.addClass('visible');//triggers css animation

            // setup click off capture event
            $(document).on('click.popover-closer', function(e){
                e.stopImmediatePropagation();
                scope.hide(id);
            });
            return elem;
        }
        return null;
    },
    hide: function(id){
        var elem = $('#popover-'+id);
        if(elem){
            elem.removeClass('visible');
            // fade out, and so on
        }
        $(document).off('click.popover-closer');
        $(document).trigger('popover.hide', [id]);
    },
    hideAll: function(){
        $('.popover.visible').removeClass('visible');
        $(document).off('click.popover-closer');
        $(document).trigger('popover.hide');
    }
}