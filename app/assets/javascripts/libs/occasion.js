(function(root, undefined) {
	"use strict";
	
	var shortMonths = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'],
		formats = /^(?:([\d]{4})|'?([\d]{2})|([a-z]+)(\.)?\s+(')?([\d]{2,4})|(\d{1,2})(\/|\-|\s)(\d{1,2})(\/|\-|\s)(\d{2,4})|([a-z]+)(\.)?\s+([\d]{1,2})(st|nd|rd|th)?(,)?\s+(')?([\d]{2,4})|([\d]{4})\/([\d]{1,2})\/([\d]{1,2})|[\d]{4}-[\d]{2}-[\d]{2})$/i;
	
	root.Occasion = function(point) {
		this._valid = false;
		this.machineDate = null;
		this.mask = null;
		
		if(point) {
			this.parse(point);
		}
	};
	
	root.Occasion.prototype.makeFullYear = function(shortYear) {
		var currentShortYear = (new Date).getFullYear() - 2000;
		return ~~shortYear + (shortYear > (currentShortYear+1) ? 1900 : 2000);
	};
	
	root.Occasion.prototype.parse = function(point) {
		var validFormat = point.match(formats);
		this._valid = false;
		
		if(validFormat !== null) {
			var explodedDate = _.filter(_.without(validFormat, undefined), function(datePart) {
				return /[\d\w]+/.test(datePart);
			});
			//TODO: Use better routing to patch year/month/day into moment
			var y = '', m = '', d = '',
				dateMask = '';
			
			if(validFormat[1]) {
				//Four digit year
				dateMask = 'YYYY';
				y = ~~validFormat[1];
				m = 0;
				d = 1;
			} else if(validFormat[2]) {
				//Two-digit year
				dateMask = point.indexOf('\'') ? '\'YY' : 'YY';
				y = this.makeFullYear(validFormat[2]);
				m = 0;
				d = 1;
			} else if(validFormat[3]) {
				//Just month and year October 2020, Jan. 1967
				dateMask = validFormat[4] ? 'MMM. ' : 'MMMM ';
				
				if(validFormat[6].length === 2) {
					dateMask += 'YY';
					y = this.makeFullYear(validFormat[6]);
				} else {
					dateMask += 'YYYY';
					y = ~~validFormat[6];
				}
				
				m = shortMonths.indexOf(validFormat[3].substring(0, 3).toLowerCase());
				d = 1;
			} else if(validFormat[7]) {
				//Full numberic dates
				dateMask  = (validFormat[7].length === 1 ? 'M' : 'MM') + validFormat[8];
				dateMask += (validFormat[9].length === 1 ? 'D' : 'DD') + validFormat[10];
				dateMask += (validFormat[11].length === 2 ? 'YY' : 'YYYY');

				y = (validFormat[11].length === 2) ? this.makeFullYear(validFormat[11]) : ~~validFormat[11];
				m = ~~validFormat[7] - 1;
				d = ~~validFormat[9];
			} else if(validFormat[12]) {
				//Alpha dates: November 11th, 1999; Feb. 29 2012, May 1 1442
				dateMask  = (validFormat[13]) ? 'MMM.' : 'MMMM';
				dateMask += ' ';
				dateMask += (validFormat[15]) ? 'Do' : (validFormat[14] && validFormat[14].length === 1 ? 'D' : 'DD');
				dateMask += (validFormat[16]) ? ', ' : ' ';
				dateMask += (validFormat[18].length === 2) ? '\'YY' : 'YYYY';
				
				y = (validFormat[18].length === 2) ? this.makeFullYear(validFormat[18]) : ~~validFormat[18];
				m = shortMonths.indexOf(validFormat[12].substring(0, 3).toLowerCase())
				d = ~~validFormat[14];
			} else if(validFormat[18]) {
				//As it comes from Rails' JSON serializer
				dateMask = 'YYYY/MM/DD';
				y = ~~validFormat[18];
				m = ~~validFormat[19] - 1;
				d = ~~validFormat[20];
			}
			
			//Naturally this will come out when moving to non-US dates
			var monthAndDayInUSFormat = (m < 12 && d < 32),
				realDateNumbers = _.any([y, m, d], function(num) {
					return num > -1;
				});
			
			if(monthAndDayInUSFormat && realDateNumbers) {
				var validMoment = moment([y, m, d]);
				
				this.date = moment([y, m, d, 12]);
				this.machineDate = validMoment.format('YYYY-MM-DD');
				this.mask = dateMask;
				this._valid = true;
			}
		}
		
		return this;
	};
		
	root.Occasion.prototype.isValid = function() {
		return this._valid;
	};

})(window);