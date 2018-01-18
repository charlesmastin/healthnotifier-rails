(function (Account) {
	"use strict";
	Account.Views.TimeoutWarning = Backbone.View.extend({
		el: '#timeout-warning',
		events: {
			'click .refresh-session': 'refreshSession',
			'click .refresh-page': 'reload'
		},
		
		initialize: function(options) {
			this.sessionManager = options.sessionManager;
		},
		
		render: function() {
			this.$('.refresh-session').text('Ok');
			this.$el.reveal({
				animation: 'fade'
			});
		},
		
		refreshSession: function(e) {
			e.preventDefault();
			
			var self = this,
				$btn = $(e.target);
			
			$btn.text('Working...');
			$.ajax({
				url: '/profiles',
				success: function(data) {
					self.$('.close-reveal-modal').click();
					self.sessionManager.resetSession();
				}, error: function(err) {
					self.$('.error-message').show();
					$btn.text('Ok');
				}
			});
		},
		
		reload: function(e) {
			e.preventDefault();
			
			document.location.reload(true);
		}
	});
})(app.module('account'));
