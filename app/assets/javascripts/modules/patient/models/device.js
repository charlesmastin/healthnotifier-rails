(function (Device, Residence) {
	"use strict";
	Device.Model = Residence.Model.extend({
		defaults: {
			health_event: '',
			health_event_type: 'DEVICE',
			start_date: undefined,
			patient_id: undefined,
			patient_health_event_id: undefined,
			'_destroy': false,
			record_order: 0
		},

		idAttribute: 'patient_health_event_id',
		
		initialize: function () {
			_.bindAll(this, 'change');
			this.incorrectDateFields = [
				'start_date'
			];
			
			this.on('change', this.evictIllegals);
			this.evictIllegals();
			this.on('change', app.reformatRailsDates, this);
			app.reformatRailsDates.call(this);
			this.collection_name = 'patient_health_events';
		}
	});
	
	
	Device.List = Residence.List.extend({
		model: Device.Model,
		
		initialize: function (models, options) {
			//_.bindAll(this);
			this.patient_id = options.patient_id;
			this.collection_name = 'patient_health_events';
		}
		
		//Do fun stuff here like custom comparator based on 'order'
	});
}(app.module('device'), app.module('residence')));
