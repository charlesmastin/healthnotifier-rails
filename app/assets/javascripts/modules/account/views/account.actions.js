$(document).off('click', 'a.delete-account');
$(document).on('click', 'a.delete-account', function(e){
    e.stopImmediatePropagation();
    $('#delete-account-modal').reveal({
        animation: 'fade'
    });
    return false;
});

// TODO: this should be handled generically since we don't need any extra prompt per the reveal built-ins
$(document).off('click', 'a.cancel-delete-account');
$(document).on('click', 'a.cancel-delete-account', function(e){
    e.stopImmediatePropagation();
    $('#delete-account-modal').trigger('reveal:close');
    return false;
});

$(document).off('click', 'a.open-exit-survey');
$(document).on('click', 'a.open-exit-survey', function(e){
    e.stopImmediatePropagation();
    $('#exit-survey').slideDown();
    return false;
});

$(document).off('change', '#exit-other-toggle');
$(document).on('change', '#exit-other-toggle', function(e){
    // e.stopImmediatePropagation();
    $('#exit-survey-other').slideDown();
    return false;
});


// handle deleting
$(document).off('click', 'a.delete-account-action');
$(document).on('click', 'a.delete-account-action', function(e){
    e.stopImmediatePropagation();

    // validate the DELETE is typed in, or complain hard
    if($('#delete-account-confirmation').val() != 'DELETE'){
        app.alert('Please enter DELETE in the confirmation field');
        $('#delete-account-confirmation').focus();
        return false;
    }
    var account_id = $(this).attr('data-account-id');
    var request_data = {
        ExitSurvey: {
            AccountId: account_id,
            Reasons: [],
            Other: $('#exit-survey-other').val()
        }
    };

    // swoop through dem checkboxes dat be checked, toss their names in a list though
    // add dat other son
    $('#exit-survey input:checked()').each(function(index, elem){
        request_data.ExitSurvey.Reasons.push($(elem).val());
    });

    // don't send if it's actually empty though
    // this is like client validation, since the form is optional
    if(request_data.ExitSurvey.Reasons.length == 0 && request_data.ExitSurvey.Other == ''){
        request_data = {};
    }

    // if we're good, send the delete to the server
    $.ajax({
        url: $(this).attr('data-url'),
        type: 'DELETE',
        dataType: 'json',
        contentType: 'application/json',
        data: JSON.stringify(request_data),
        success: function(data){
            if(request_data != {}){
                window.location = '/exit-survey/success';
            }else {
                window.location = '/goodbye?account=' + account_id;
            }
        },
        error: function(data){
            app.alert('Error deleting account. Please try again or contact support@lifesquare.com for assistance.');
        }
    });

    // broadcast an event, so we can do appropriate things on the views we're on    
    return false;
});