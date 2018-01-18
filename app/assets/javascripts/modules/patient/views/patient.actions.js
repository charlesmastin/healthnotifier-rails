// common event handlers and logic to perform generic actions on a patient
// written in the detail context, but might as well, assume a generic context (list of patients) so any relevant patient data should be passed in
// most should be split off into "view controllers" for each unit of functionality, really each modal ui
// this is lazy town
// this is designed to be setup / torn down around the scope of patient views, not the global scope, lol

// export

/*
(function (Patient) {
    "use strict";

    Patient.Views.Actions = Backbone.View.extend({        
        events: {
            'click a.export-records': 'showExportModal',
        },

        initialize: function(options){
            _.bindAll(this, 'showExportModal');
        },

        showExportModal: function(e){
            $('#export-modal').reveal({
                animation: 'fade'
            });
            return false;
        }

    });

}(app.module('patient')));
*/
$(document).off('click', 'a.export-records');
$(document).on('click', 'a.export-records', function(e){
    e.stopImmediatePropagation();
    $('#export-modal').reveal({
        animation: 'fade'
    });
    popover.hideAll();
    return false;
});

$(document).off('click', 'a.cancel-export-records');
$(document).on('click', 'a.cancel-export-records', function(e){
    e.stopImmediatePropagation();
    $('#export-modal').trigger('reveal:close');
    return false;
});

$(document).off('click', 'a.action-download-records');
$(document).on('click', 'a.action-download-records', function(e){
    $('#export-modal div.initial').hide();
    $('#export-modal div.success').show();

    $('#export-modal .modal-flow-control.initial').hide();
    $('#export-modal .modal-flow-control.success').show();
});

$(document).off('click', 'a.import-records');
$(document).on('click', 'a.import-records', function(e){
    e.stopImmediatePropagation();
    $('#import-modal').reveal({
        animation: 'fade'
    });
    popover.hideAll();
    return false;
});

// TODO: MOVE SOMEWHERE ELSE SON
$(document).off('click', 'a.delete-patient');
$(document).on('click', 'a.delete-patient', function(e){
    e.stopImmediatePropagation();
    $('#delete-patient-modal').reveal({
        animation: 'fade'
    });
    popover.hideAll();
    return false;
});

// TODO: this should be handled generically since we don't need any extra prompt per the reveal built-ins
$(document).off('click', 'a.cancel-delete-patient');
$(document).on('click', 'a.cancel-delete-patient', function(e){
    e.stopImmediatePropagation();
    $('#delete-patient-modal').trigger('reveal:close');
    return false;
});

$(document).off('click', 'a.delete-patient-action');
$(document).on('click', 'a.delete-patient-action', function(e){
    e.stopImmediatePropagation();

    // validate the DELETE is typed in, or complain hard
    if($('#delete-patient-confirmation').val() != 'DELETE'){
        app.alert('Please enter DELETE in the confirmation field');
        $('#delete-patient-confirmation').focus();
        return false;
    }

    var patient_id = $(this).attr('data-patient-uuid');

    // if we're good, send the delete to the server
    $.ajax({
        url: $(this).attr('data-url'),
        type: 'DELETE',
        contentType: 'application/json',
        success: function(data){
            $(document).trigger('onPatientDelete', [patient_id]);
            $('#delete-patient-modal').trigger('reveal:close');
        },
        error: function(data){
            app.alert('Error deleting patient. Please try again or contact support@lifesquare.com for assistance.');
        }
    });

    // broadcast an event, so we can do appropriate things on the views we're on    
    return false;
});

$(document).off('onPatientDelete');
$(document).on('onPatientDelete', function(e, patient_id){
    // this is the quick and dirtyy handler
    // remove da item, technically, move it seamlessly to the deleted side
    // so let's cheat, and "wait for the modal to close" and then reload
    setTimeout(function(){
        // TODO: lalalalal hard-coded routes fail town
        if(window.location.pathname == "/profiles"){
            window.location.reload();
        }else {
            window.location = '/profiles';
        } 
    }, 500);
});

$(document).off('click', 'a.action-cancel-subscription');
$(document).on('click', 'a.action-cancel-subscription', function(e){
    // sniff out the patient_id
    e.stopImmediatePropagation();
    $(this).addClass('disabled').removeClass('action-cancel-subscription').attr('disabled', 'disabled').text('Cancelling…');
    // TODO: lock UI at this point
    var patient_id = $(this).attr('data-patient-id');
    $.ajax({
        url: $(this).attr('data-url'),
        type: 'DELETE',
        contentType: 'application/json',
        success: function(data){
            $(document).trigger('onSubscriptionCancel', [patient_id]);
            app.alert('Coverage subscription cancelled');
            // $('#cancel-subscription-modal').trigger('reveal:close');
        },
        error: function(data){
            app.alert('Error cancelling subscription. Please try again or contact support@lifesquare.com for assistance.');
        }
    });
    return false;
});

// TODO: MOVE SOMEWHERE ELSE SON
/*
$(document).on('click', 'a.action-feedback', function(e){
    e.stopImmediatePropagation();
    UserSnap.openReportWindow();
    return false;
});
*/

$(document).off('click', 'a.cancel-subscription');
$(document).on('click', 'a.cancel-subscription', function(e){
    e.stopImmediatePropagation();
    $('#cancel-subscription-modal').reveal({
        animation: 'fade'
    });
    return false;
});

// TODO: this should be handled generically since we don't need any extra prompt per the reveal built-ins
$(document).off('click', 'a.cancel-cancel-subscription');
$(document).on('click', 'a.cancel-cancel-subscription', function(e){
    e.stopImmediatePropagation();
    $('#cancel-subscription-modal').trigger('reveal:close');
    return false;
});