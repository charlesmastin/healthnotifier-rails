"use strict";
window.app = {
    module: function () {
        var modules = {};

        // Create a new module reference scaffold or load an existing module.
        return function (name) {
            if (modules[name]) {
                return modules[name];
            }
            return modules[name] = { Views: {}, Models: {}, Collections: {} };
        };
    }(),

    language: 'en',

    confirm: function(options, callback, cancel) {
        swal(
            options,
            function(isConfirm){
                if (isConfirm) {
                    if(callback != undefined){
                        callback();
                    }
                } else {
                    if(cancel != undefined){
                        cancel();
                    }      
                }
            }
        );
    },

    alert: function(msg, callback, cancel){
        swal({
            title: "",
            text: msg,
            html: true,
            allowOutsideClick: true,
            type: "warning"
            },
            function(isConfirm){
                if (isConfirm) {
                    if(callback != undefined){
                        callback();
                    }
                } else {
                    if(cancel != undefined){
                        cancel();
                    }      
                }
            }
        );
    },

    //Rails sends dates in a strange form. Let's fix that.
    reformatRailsDates: function() {
        var self = this,
            railsDateFormat = /(\d{4})-(\d{2})-(\d{2})/,
            updateObj = {};

        _.each(self.incorrectDateFields, function(field) {
            if(railsDateFormat.test(self.attributes[field])) {
                var matches = self.attributes[field].match(railsDateFormat);

                updateObj[field] = [matches[2], matches[3], matches[1]].join('/');
            }

        });
        self.set(updateObj);
    },

    formatPhone: function(value){
        // if we're a US phone, use that
        // otherwise, just toss it in there
        if(value == ''){
            return value;
        }
        if(!value || value == undefined || value == null){
            return '';
        }
        var matches = value.match(/\d+/g);
        if(matches != null && matches.length > 0){
            var digits = matches.join([]);
            if(digits.length == 10 || (digits.length == 11 && digits.charAt(0) == 1)){
                // we're american (ish)
                return this.formatUsPhone(value);
            }
            // meh for extensions on US phones
        }
        return value;
    },

    formatUsPhone: function(phoneNum) {
        if (!phoneNum) return '';

        var extSplit = phoneNum.split(/x/i),
            digits = extSplit[0].replace(/[^\d]/g, ''),
            formatted = phoneNum;

        if(digits.length > 11) {
            //User did something unexpected. BAIL!
            formatted = phoneNum;
        } else if(digits.length > 10) {
            formatted = digits.substring(0, 1) + ' (' + digits.substring(1,4) + ') ' + digits.substring(4, 7) + '-' + digits.substring(7, digits.length);
        } else if(digits.length > 7) {
            formatted = '(' + digits.substring(0,3) + ') ' + digits.substring(3, 6) + '-' + digits.substring(6, digits.length);
        } else if(digits.length > 3) {
            formatted = digits.substring(0, 3) + '-' + digits.substring(3, digits.length);
        }

        return formatted + (extSplit.length > 1 ? ' x' + extSplit[1] : '');
    },

    trackPageView: function(url) {
        if( window._gaq ) {
            _gaq.push(['_trackPageview', url]);
        }
    },

    handleDobDown: function(e){
        if(e.which == 8 || e.which == 27 || e.which == 9 || (e.which >= 48 && e.which <= 57)){
            
        } else {
            e.preventDefault();
            e.stopImmediatePropagation();
        }
    },

    handleDobUp: function(e){
        var elem = $(e.currentTarget);
        if(e.which != 8){
            if(elem.val().length == 2 || elem.val().length == 5){
                elem.val(elem.val() + "/");
            }
        }
    },

    showFlashMessage: function(message, level, scroll){
        // TODO: hooking dis with the sweetalerts to be more up in your grille
        // proper full on config would be
        /*
        {
            message: '<a href="#">sweet link</a> html safe example',
            level: 'notice' || 'error'
            focus: true || false
            sticky: true || false (can it be dismissed with a close button)
        }
        */

        if(level == undefined){
            level = 'notice';
        }
        // this is the in-place guy, it will replace an existing message, or render the dom fresh fresh if needed
        if($('main > .notification').length){
            // use this one
            $('main > .notification').text(message);// add some css class to flash it, lulzor
            // strip any extra classes, add our level
        }else{
            // create dom
            $('main').prepend($('<div class="notification notice">' + message + '</div>'));
        }
        $('main > .notification').removeClass('*').addClass('notification', level);
        if(scroll != undefined && scroll){
            $(window).stop().scrollTo($('header')[0] , 800 );
        }

        // this is dangerous… ish™
        if(message == app.messages.WARNING_SESSION_TIMEOUT_AND_REDIRECT){
            setTimeout(function(){
                var url = '/login';
                if(location.pathname != url){
                    url = url + '?next=' + location.pathname;
                }
                window.location = url; // TODO and apply the next aspect
            }, 1500);
        }
    },

    calculateStuckTown: function(e){
        if($('#patient-transaction-bar').length){
            var hh = 56;// calculate for reals
            var st = $(window).scrollTop();
            if(st >= hh){
                $('body').addClass('stucktown');
            }else{
                $('body').removeClass('stucktown');
            }
        }
    },

    calculateStuckTownOffset: function(){
        if($('#patient-transaction-bar').length){
            return 56;
        }else{
            return 0;
        }
    }

};

//OHAI IE8!
//https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/IndexOf
if (!Array.prototype.indexOf) {
    Array.prototype.indexOf = function(elt /*, from*/) {
        var len = this.length >>> 0;
        var from = Number(arguments[1]) || 0;

        from = (from < 0)
             ? Math.ceil(from)
             : Math.floor(from);

        if (from < 0)
            from += len;

        for (; from < len; from++) {
            if (from in this && this[from] === elt)
                return from;
        }
        return -1;
    };
}

// Patch JSON.stringify for IE 8 on XP
// Weirdly, some incoming values from the DOM === "" but stringify to "null"
// It's an issue with JSON.stringify in IE 8, which I tried to monkeypatch
//  first, but it probably calls itself recursively, so that didn't work
// Instead, this workaround from MS patches the HTML input element to set the
//  retrieved value to "" if it === ""
if (JSON.stringify(document.createElement("input").value) === '"null"') {
    (function() {
        var builtInInputValue = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").get;
        Object.defineProperty(
            HTMLInputElement.prototype,
            "value",
            {
                get: function() {
                      var possiblyBad = builtInInputValue.call(this);
                      return possiblyBad === "" ? "" : possiblyBad;
                }
            }
        );
    })();
}

function qs(key) {
    key = key.replace(/[*+?^$.\[\]{}()|\\\/]/g, "\\$&"); // escape RegEx meta chars
    var match = location.search.match(new RegExp("[?&]"+key+"=([^&]+)(&|$)"));
    return match && decodeURIComponent(match[1].replace(/\+/g, " "));
}

_.templateSettings = {
    interpolate: /\{\{(.+?)\}\}/g,
    evaluate: /\[\[(.+?)\]\]/g
};


$.ajaxSetup({
    'beforeSend' : function(xhr){
        xhr.setRequestHeader("Accept", "application/json");
        xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
    }
});


$(document).ready(function() {

    $('input, textarea').placeholder();

    // graveyard of generic catch-all js event handling


    // global modal hackinzators
    $(document).off('click', 'a.privacy-tooltip');
    $(document).on('click', 'a.privacy-tooltip', function(e){
        e.stopImmediatePropagation();
        $('#privacy-details-modal').reveal({
            animation: 'fade'
        });
        popover.hideAll();
        return false;
    });

    // wow, that's a mouthful
    var handleCloseDropDown = function(e){
        $('#account-dropdown').removeClass('visible');
        $(document).off('click', this);
    }
    $(document).off('click', 'a.account-drop-trigger');
    $(document).off('click', handleCloseDropDown);
    $(document).on('click', 'a.account-drop-trigger', function(e){
        $('#account-dropdown').toggleClass('visible');
        $(document).off('click', handleCloseDropDown);
        if($('#account-dropdown').hasClass('visible')){
            $(document).on('click', handleCloseDropDown);
        }
        popover.hideAll();
        return false;
    });
    
    // TODO: huh?
    $(document).on('click', '.ghetto-webview-tab-controller a', function(e){
        // e.stopImmediatePropagation();
        var section = $(e.target.hash);
        $('.ghetto-webview-tab-controller .active').removeClass('active');
        $(e.target).parent().addClass('active');
        //$(window).stop().scrollTo( section , 800 );
        $('.webview .tab.active').removeClass('active');
        section.addClass('active');
        location.hash = 'section-'+(e.target.hash).substr(1);

        $('#popover-privacy-filter a').each(function(index, elem){
            elem.href = $(elem).attr('data-base-href') + location.hash;
        });

        return false;
    });

    $(document).off('renderNotification');
    $(document).on('renderNotification', function(e, notification){
        e.stopImmediatePropagation();
        // TODO: actually build a component, SON
        if($('.notification-center').length){
            $('.notification-center').remove();
        }   

        $('body').append('<section class="notification-center"><article><p><i class="material-icons">check_circle</i>' + notification.message + '</p></article></section>');
        // $('.notification-center article').addClass('visible');
        setTimeout(function(){
            $('.notification-center').fadeIn();
        }, 250);

        setTimeout(function(){
            $('.notification-center').fadeOut();
        }, 5000);
    });

    // scroll handlers for the sticky business of the transaction bar, yea son
    $(window).on('scroll', function(e){
        app.calculateStuckTown();
    });

    app.calculateStuckTown();

});

// THE PILE OF SHAME
// http://fiddle.jshell.net/da5LN/62/light/
function pieChart(percentage, size, color) {
    var svgns = "http://www.w3.org/2000/svg";
    var chart = document.createElementNS(svgns, "svg:svg");
    chart.setAttribute("width", size);
    chart.setAttribute("height", size);
    chart.setAttribute("viewBox", "0 0 " + size + " " + size);
    // Background circle
    var back = document.createElementNS(svgns, "circle");
    back.setAttributeNS(null, "cx", size / 2);
    back.setAttributeNS(null, "cy", size / 2);
    back.setAttributeNS(null, "r",  size / 2);
    var color = "#555";
    /*
    if (size > 50) { 
        color = "#ebebeb";
    }
    */
    back.setAttributeNS(null, "fill", color);
    chart.appendChild(back);
    // primary wedge
    var path = document.createElementNS(svgns, "path");
    var unit = (Math.PI *2) / 100;    
    var startangle = 0;
    var endangle = percentage * unit - 0.001;
    var x1 = (size / 2) + (size / 2) * Math.sin(startangle);
    var y1 = (size / 2) - (size / 2) * Math.cos(startangle);
    var x2 = (size / 2) + (size / 2) * Math.sin(endangle);
    var y2 = (size / 2) - (size / 2) * Math.cos(endangle);
    var big = 0;
    if (endangle - startangle > Math.PI) {
        big = 1;
    }
    var d = "M " + (size / 2) + "," + (size / 2) +  // Start at circle center
        " L " + x1 + "," + y1 +     // Draw line to (x1,y1)
        " A " + (size / 2) + "," + (size / 2) +       // Draw an arc of radius r
        " 0 " + big + " 1 " +       // Arc details...
        x2 + "," + y2 +             // Arc goes to to (x2,y2)
        " Z";                       // Close path back to (cx,cy)
    path.setAttribute("d", d); // Set this path 
    path.setAttribute("fill", '#33D3AA');
    chart.appendChild(path); // Add wedge to chart
    // foreground circle
    var front = document.createElementNS(svgns, "circle");
    front.setAttributeNS(null, "cx", (size / 2));
    front.setAttributeNS(null, "cy", (size / 2));
    front.setAttributeNS(null, "r",  (size * 0.35)); //about 34% as big as back circle 
    front.setAttributeNS(null, "fill", "#252525");
    chart.appendChild(front);
    return chart;
}


//Tack in mutator hooks
_.extend(Backbone.Model.prototype, Backbone.Mutators.prototype);
