"use strict";
_.extend(Backbone.Validation.validators, {
    naturalDate: function(value, attr, customValue, model) {
        if(!_.isString(value) || value.length === 0) {
            return 'error';
        }

        var occasion = new Occasion(value);
        if(!occasion.isValid() || occasion.date.year() < 1900) {
            return 'error';
        }
    },

    railsJsonDate: function(value, attr, customValue, model) {
        if(!_.isString(value) || value.length === 0 || /[\d]{4}-[\d]{2}-[\d]{2}/.test(value) === false) {
            return 'error';
        }
    },

    usDate: function(value, attr, customValue, model) {
        if(!_.isString(value) || value.length === 0) {
            return 'error';
        }

        var formats = [
            /[\d]{1,2}-[\d]{1,2}-[\d]{2,4}/,
            /[\d]{1,2}\/[\d]{1,2}\/[\d]{2,4}/
        ];
        var meetsFormat = _.any(formats, function(format) {
            return format.test(value);
        });

        var occasion = new Occasion(value);

        if( meetsFormat === false || !occasion.isValid() ) {
            return 'error';
        }
        // var elements = model.dateElements(value);
        // if(!elements.date || !elements.mask) {
        //  return 'error';
        // }
    },

    phone: function(value, attr, customValue, model) {
        // TODO: wrap some more sophisiticated library here
        // just do a basic check now, for at least 10 numbers
        var matches = value.match(/\d+/g);
        if(value != '' && matches == null){
            return 'error';
        }
        if(matches != null && matches.length > 0){
            var digits = matches.join([]);
            if(digits.length >= 10){
                
            } else {
                return 'error';
            }
        } else {
            return 'error';
        }
        
    },

    usPhone: function(value, attr, customValue, model) {
                if (!value) return;
        var matches = value.match(/^(.*?)(x[\d]+)?$/i),
            hasExtension = matches[2] ? /x[\d]+$/i.test(matches[2]) : false,
            digits = matches[1].replace(/[^\d]/g, '');

        if(digits.length < 10) {
            return 'error';
        } else if(digits.length > 10) {
            if(digits.length === 11 && digits.substring(0, 1) === '1') {
                return '';
            } else if (hasExtension === false) {
                return 'error';
            }
        }
    },

    futureDate: function(value, attr, customValue, model) {
        var occasion = new Occasion(value),
            now = moment(new Date);
        if(!occasion.isValid() || occasion.date < now) {
            return 'error';
        }
    },

    usPostalCode: function(value, attr, customValue, model) {
        var postalCodePattern = /^([\d]{5})(?:-[\d]{4})?$/;
        if( postalCodePattern.test(value) === false ) {
            return 'error';
        }
    },
    
    password: function(value, attr, customValue, model) {
        var minLength = 8,
            valid = value.length >= minLength && !!value.match(/[a-zA-Z]/) && (!!value.match(/[\d]/) || !!value.match(/[^\w\d]/));

        if(valid === false) return 'error';
    }
});

_.extend(Backbone.Validation.patterns, {
    usPostalCode: /^([\d]{5})(?:-[\d]{4})?$/,
    lifesquareCode: /^[a-z0-9]{3}(?:\s|\-)?[a-z0-9]{3}(?:\s|\-)?[a-z0-9]{3}$/i,
    usDate: /^(?:([\d]{4})|'?([\d]{2})|([a-z]+)(\.)?\s+(')?([\d]{2,4})|(\d{1,2})(\/|\-|\s)(\d{1,2})(\/|\-|\s)(\d{2,4})|([a-z]+)(\.)?\s+([\d]{1,2})(st|nd|rd|th)?(,)?\s+(')?([\d]{2,4})|([\d]{4})\/([\d]{1,2})\/([\d]{1,2})|[\d]{4}-[\d]{2}-[\d]{2})$/i
});
