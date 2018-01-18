(function (Account) {
	"use strict";
	Account.Views.Social = Backbone.View.extend({
		events: {
			'click .close-icon': 'close',
			'change #refer': 'saveRefer'
		},
		
		initialize: function(options) {
			_.bindAll(this, 'render', 'close', 'saveRefer');
			this.render();
		},
		
		render: function(options) {
			this.$('.set-refer').show();
			this.$('.show-thanks').hide();
		},
		
		close: function(e) {
			e.preventDefault();
			
			var self = this;
			
			self.$el.animate({
				opacity: 0,
				'padding-bottom': 0,
				'padding-top': 0,
				'margin-bottom': 0,
				height: 'toggle'
			});
		},
		
		saveRefer: function(e) {
			e.preventDefault();
			
			var form = e.target.form,
				$referForm = this.$('.set-refer'),
				$thanks = this.$('.show-thanks');
			
			$.ajax({
				url: form.action,
				type: 'put',
				data: {
					refer: e.target.value
				},
			}).done(function() {
				$referForm.hide();
				$thanks.show();
			}).fail(function() {
				$referForm.show();
				$thanks.hide();
			});
			e.target.blur();
		}
	});
})(app.module('account'));