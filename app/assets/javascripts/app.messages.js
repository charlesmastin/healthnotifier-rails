//Room for i18n
app.messages = (function(lang){
	lang || (lang='en');
	var messages = {
		en: {
			ERROR_AJAX: 'An error occurred on the server. Please try again in a few moments.',
			ERROR_INVALID_FORM_FIELDS: 'It appears as though some fields aren\'t filled in correctly.<br>Please check the error messages in the form and try submitting again.',
			ERROR_MEDICATION_FREQUENCY_REQUIRED: 'Medication frequency is required.',
			ERROR_MEDICATION_NAME_REQUIRED: 'Medication name is required.',
			ERROR_MEDICATION_NOT_SELECTED: 'Medication not selected from list provided.',
			ERROR_MEDICATION_QUANTITY_REQUIRED: 'Medication quantity is required.',
			ERROR_SUBMITTING_FORM: 'There was an error submitting the form. Please check your form and try again.',
			ERROR_THUMBNAIL_TOO_SMALL: 'Please choose a higher resolution photo (at least 127px x 127px). Make sure it features your face so medical personnel can identify you.',
			WARNING_DELETE_ALL_ENTRIES: 'This will remove all entries. Continue?',
			WARNING_DELETE_ALLERGY: 'Really remove allergy?',
			WARNING_DELETE_IMMUNIZATION: 'Really remove immunization?',
			WARNING_DELETE_CONDITION: 'Really remove condition?',
			WARNING_DELETE_CONTACT: 'Really remove this contact?',
			WARNING_DELETE_DIRECTIVE: 'Really remove this directive?',
			WARNING_DELETE_DEVICE: 'Really remove device?',
			WARNING_DELETE_HOSPITAL: 'Really remove this hospital?',
			WARNING_DELETE_IMAGE: 'Really delete image?',
			WARNING_DELETE_INSURANCE: 'Really remove this insurance?',
			WARNING_DELETE_MEDICATION: 'Really remove medication?',
			WARNING_DELETE_LANGUAGE: 'Really remove this language?',
			WARNING_DELETE_PHARMACY: 'Really remove this pharmacy?',
			WARNING_DELETE_PHYSICIAN: 'Really remove this physician?',
			WARNING_DELETE_PROCEDURE: 'Really remove procedure?',
			WARNING_DELETE_RESIDENCE: 'Really remove this residence?',
			WARNING_MISSING_CROP: 'Close without cropping your image?',
			WARNING_MISSING_PATIENT_PHOTO: 'Close without choosing photo?',
			WARNING_REMOVE_CONTACT: 'Really remove contact?',
			WARNING_SESSION_TIMEDOUT: 'Your session has timed out. Please log in and return to this page.',
			WARNING_SESSION_TIMEOUT_AND_REDIRECT: 'Your session has timed out. Redirecting you to the login page&hellip;',
			WARNING_UNLOAD_UNSAVED_DATA: 'There have been changes made. Any unsaved changes will be lost.'
		},
		fr: {
			WHUT: 'Why would you ever do this?'
		}
	};


	return messages[lang];
})(app.language);
