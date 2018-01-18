(function (Signup, Utilities) {
  "use strict";
  Signup.Views.Provider = Backbone.View.extend({
    events: {
      'click .patients-summary.selectable article': 'setPatient',
      'click a.submit-credentials': 'validate',
      'keyup #license-expiration': 'handleDobUp',
      'keypress #license-expiration': 'handleDobDown',
    },

    initialize: function(options) {
      _.bindAll(this, 'validate', '_validate', 'submit', '_submit');

      // meh?
      this.render(options);

      // set active on first item
      $('.patients-summary article:first-child').addClass('active');

    },

    handleDobDown: function(e){
      window.app.handleDobDown(e);
    },

    handleDobUp: function(e){
      window.app.handleDobUp(e);
    },

    setPatient: function(e){
      $('.patients-summary.selectable .active').removeClass('active');
      $(e.target).addClass('active');
    },

    validate: function(e){
      var errors = this._validate();
      if(errors.length){
          var r = '';
          for(var obj in errors){
              r += errors[obj].message + '\n';
          }
          app.alert('You have a few validation errors\n-------------\n' + r);
      } else {
          this.submit();
      }
      return false;
    },

    _validate: function() {
      // TODO: hook a legit form validation library or something, maybe, maybe not
      // check all the fields, one by one, beca
      var errors = [];
      if($('input[name="license-number"]').val() == ''){
          errors.push({
              field: $('input[name="license-number"]'),
              message: "License Number required"
          });
      }
      if($('input[name="license-board"]').val() == ''){
          errors.push({
              field: $('input[name="license-board"]'),
              message: "Licensing Board required"
          });
      }
      if($('select[name="state_province"]').val() == ''){
          errors.push({
              field: $('select[name="state_province"]'),
              message: "Licensing state required"
          });
      }
      // THIS IS TERRIBLE AND WE KNOW IT
      if($('input[name="expiration"]').val().length != '10'){
          errors.push({
              field: $('input[name="expiration"]'),
              message: "Licensing expiration required - MM/DD/YYYY"
          });
      }
      if($('input[name="supervisor-name"]').val() == ''){
          errors.push({
              field: $('input[name="supervisor-name"]'),
              message: "Supervisor name required"
          });
      }
      if($('input[name="supervisor-email"]').val() == ''){
          // TODO: check against email regex, but fortunately, input[type="email"] helps with some of it
          errors.push({
              field: $('input[name="supervisor-email"]'),
              message: "Supervisor email required"
          });
      }
      if($('input[name="supervisor-phone"]').val() == ''){
          errors.push({
              field: $('input[name="supervisor-phone"]'),
              message: "Supervisor phone required"
          });
      }

      // check the confirmation checkbox last
      // TODO: add the text input UI DELETE pattern to delete account and delete patient
      if(!$('input[name="confirmation"]').prop('checked')){
          errors.push({
              field: $('input[name="confirmation"]'),
              message: "Please confirm you are a licensed professional"
          });   
      }
      return errors;
    },

    formatFile: function(d){
      // SOOOOOOOOOOOOON we will have a single properly cleaned API, back to front, front to back
        return {
            File: d.file,
            Name: d.name,
            Mimetype: d.mimetype
        }
    },

    submit: function(){
      var scope = this;
      scope.lock();

      // parse input strip it son
      var data = {
          LicenseNumber: $('input[name="license-number"]').val(),
          LicenseBoard: $('input[name="license-board"]').val(),
          State: $('select[name="state_province"]').val(),
          Expiration: $('input[name="expiration"]').val(),
          SupervisorName: $('input[name="supervisor-name"]').val(),
          SupervisorEmail: $('input[name="supervisor-email"]').val(),
          SupervisorPhone: $('input[name="supervisor-phone"]').val(),
          SupervisorExt: $('input[name="supervisor-ext"]').val()
      }

      // TODO: extend to handle inbound patient selection : LOL SON, optional attribute beezy
      try {
          data['PatientId'] = $('.patients-summary article.active').attr('data-patient-uuid');
      } catch(e){
          // server will use defaults, so it's really ok here
      }

      // files, oh I forget already
      var promises = [];
      if($('input[name="credentials-file-1"')[0].files.length){
          promises.push(Utilities.Data.convertFileInputToBase64( $('input[name="credentials-file-1"') ));
      }
      if($('input[name="credentials-file-2"')[0].files.length){
          promises.push(Utilities.Data.convertFileInputToBase64( $('input[name="credentials-file-2"') ));
      }
      if(promises.length){
          // it's unclear how to pass an array of promises, go jquery you suck
          // this is literally some of the most ghetto code ever
          // according to J, some people take offense to that
          if(promises.length == 2){
              $.when(promises[0], promises[1]).done(function(d1, d2){
                  data['CredentialFiles'] = [scope.formatFile(d1), scope.formatFile(d2)];
                  scope._submit(data);
              });
          }else{
              $.when(promises[0]).done(function(d1){
                  data['CredentialFiles'] = [scope.formatFile(d1)];
                  scope._submit(data);
              });
          }
      }else {
          scope._submit(data);
      }
    },

    _submit: function(data){
      var scope = this;
      var API_ENDPOINT = this.$el.attr('data-action');
      var SUCCESS_URL = this.$el.attr('data-success');

      $.ajax({
          url: API_ENDPOINT,
          type: 'POST',
          dataType: 'json',
          contentType: 'application/json',
          data: JSON.stringify(data),
          success: function(data){
              // redirect yoself, assume server side notification / aka messages
              window.location = SUCCESS_URL;
          },
          error: function(data){
              if(data.status == 401){
                  app.alert('Error: Unauthorized');
              }
              if(data.status == 404){
                  app.alert('Error: Invalid Lifesquare Profile');
              }
              if(data.status == 500){
                  app.alert('Error: Credentialing in-progress or other error');
              }
              scope.unlock();
          }
      });
    },

    lock: function(){
      $('a.submit-credentials').addClass('disabled').removeClass('submit-credentials').attr('disabled', 'disabled').text('Sending…');
    },

    unlock: function(){
      $('.flow-control .button.primary').removeClass('disabled').addClass('submit-credentials').removeAttr('disabled').text('Submit');
    }

  });
}(app.module('signup'), app.module('utilities')));
