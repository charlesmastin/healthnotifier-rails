(function(Utilities) {
  'use strict';
  Utilities.Data = Utilities.Data || {};

  // this is actually convert input[type="file"] vs say, a fileobject, which is a better abstraction
  Utilities.Data.convertFileToBase64 = function(file, filename) {
    var dfd = new jQuery.Deferred();
    // type check that mofo
    var reader = new FileReader();

    reader.onload = function(f) {
      var d = f.srcElement.result;
      var fname = 'new-uploaded-file.jpg';
      if(filename != undefined){
        fname = filename;
      }
      var json = {
        Name: fname,
        File: d.substr(d.indexOf('base64')+6),
        Mimetype: d.split(';')[0].split(':')[1] // ghetto as hell
      };

      dfd.resolve(json);
    };

    reader.onerror = function(){
      dfd.reject(new Error('Error Loading'));
    };

    reader.readAsDataURL(file);

    return dfd.promise();
  };

  Utilities.Data.convertFileInputToBase64 = function(elem) {
    // We could do this with regular messaging, but this is more generic / useful for other scenarios
    var dfd = new jQuery.Deferred();
    if(elem.get(0).files[0]) {
      var reader = new FileReader();

      reader.onload = function(f) {
        // parse out base64 string from a util method
        var d = f.srcElement.result;
        // TODO: convert the case here when we have propagated all the changes, for now it's a jumbo-mess-a-tron™
        var json = {
          name: elem.val().substr(elem.val().lastIndexOf('\\')+1),
          file: d.substr(d.indexOf('base64')+6),
          mimetype: d.split(';')[0].split(':')[1]
        };

        dfd.resolve(json);
      };

      reader.onerror = function(){
        dfd.reject(new Error('Error Loading'));
      };

      reader.readAsDataURL(elem.get(0).files[0]);
    } else {
      dfd.reject(new Error('No File Object'));
    }

    return dfd.promise();
  };

}(app.module('utilities')));
