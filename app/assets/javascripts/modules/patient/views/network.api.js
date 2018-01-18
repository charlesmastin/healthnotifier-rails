$(function(){
    window.networkApi = {
        // this can't be statically configured, sadly
        search: function(patientId, data, success, error){
            $.ajax({
                url: '/api/v1/profiles/' + patientId + '/network/search',
                type: 'GET',
                dataType: 'json',
                data: data,
                success: function(data){
                    success(data);
                },
                error: function(data){
                    error(data);
                }
            });
        },

        add: function(data, success, error){
            $.ajax({
                url: '/api/v1/profiles/' + data.GranterId + '/network/add',
                type: 'POST',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(data),
                success: function(data){
                    success(data);
                },
                error: function(data){
                    error(data);
                }
            });
        },

        request_access: function(data, success, error){
            $.ajax({
                url: '/api/v1/profiles/' + data.AuditorId + '/network/request-access',
                type: 'POST',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(data),
                success: function(data){
                    success(data);
                },
                error: function(data){
                    error(data);
                }
            });
        },
        
        accept: function(data, success, error){
            $.ajax({
                url: '/api/v1/profiles/' + data.GranterId + '/network/accept',
                type: 'POST',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(data),
                success: function(data){
                    success(data);
                },
                error: function(data){
                    error(data);
                }
            });
        },

        decline: function(data, success, error){
            $.ajax({
                url: '/api/v1/profiles/' + data.GranterId + '/network/decline',
                type: 'POST',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(data),
                success: function(data){
                    success(data);
                },
                error: function(data){
                    error(data);
                }
            });
        },

        update: function(data, success, error){
            $.ajax({
                url: '/api/v1/profiles/' + data.GranterId + '/network/update',
                type: 'PUT',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(data),
                success: function(data){
                    success(data);
                },
                error: function(data){
                    error(data);
                }
            });
        },

        revoke: function(data, success, error){
            $.ajax({
                url: '/api/v1/profiles/' + data.GranterId + '/network/revoke',
                type: 'DELETE',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(data),
                success: function(data){
                    success(data);
                },
                error: function(data){
                    error(data);
                }
            });
        },

        leave: function(data, success, error){
            $.ajax({
                url: '/api/v1/profiles/' + data.AuditorId + '/network/leave',
                type: 'DELETE',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(data),
                success: function(data){
                    success(data);
                },
                error: function(data){
                    error(data);
                }
            });
        }

    }
});