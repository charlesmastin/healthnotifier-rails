// this is the set of JS to manage a request level
// also existing connection where you are the granter

// for now we's gonna do a location reload on dis bizzle
// until we have a view managers and all da views in js
// aka, until we rebuild dis sizzle with da react/redux/donkeyslips son

// also , until we do that, and simply reload stuffs, we're gonna use this as a collection view
// GOTCHA!

// this is temp, and it's gonna work

// bind events to the class
// go up to the popover, lolololol
// read the data for the auditor
// and the granter, and do your thing
// these be naked son

$(function(){
    // unsure of event binding syntax, document or the element itself, w/e not relevant
    function dd007_getNetworkIds(element){
        var p = $(element).parents('.popover');
        return {
            AuditorId: p.attr('data-auditor-id'),
            GranterId: p.attr('data-granter-id')
        }
    }
    function dd007_addNetworkConnection(e, level){
        var data = dd007_getNetworkIds(e.target);
        data.Privacy = level;
        networkApi.add(
            data,
            function(data){
                window.location.reload();
            },
            function(data){
                // error ,lolz
                app.alert(data);
            }
        );
    }
    function dd007_acceptNetworkConnection(e, level){
        var data = dd007_getNetworkIds(e.target);
        data.Privacy = level;
        networkApi.accept(
            data,
            function(data){
                window.location.reload();
            },
            function(data){
                app.alert(data);
            }
        );
    }

    function dd007_updateNetworkConnection(e, level){
        var data = dd007_getNetworkIds(e.target);
        data.Privacy = level;
        networkApi.update(
            data,
            function(data){
                // 
                //window.alert('Permission Updated');
                window.location.reload();
            },
            function(data){
                app.alert(data);
            }
        );
    }
    $(document).off('click', 'a.action-network-decline');
    $(document).on('click', 'a.action-network-decline', function(e){
        e.stopImmediatePropagation();
        var data = dd007_getNetworkIds(e.target);
        networkApi.decline(
            data,
            function(data){
                window.location.reload();
            },
            function(data){
                app.alert(data);
            }
        );
        return false;
    });

    $(document).off('click', 'a.action-network-revoke');
    $(document).on('click', 'a.action-network-revoke', function(e){
        e.stopImmediatePropagation();
        var data = dd007_getNetworkIds(e.target);
        networkApi.revoke(
            data,
            function(data){
                window.location.reload();
            },
            function(data){
                app.alert(data);
            }
        );
        return false;
    });
    $(document).off('click', 'a.action-network-leave');
    $(document).on('click', 'a.action-network-leave', function(e){
        e.stopImmediatePropagation();
        var data = dd007_getNetworkIds(e.target);
        networkApi.leave(
            data,
            function(data){
                window.location.reload();
            },
            function(data){
                app.alert(data);
            }
        );
        return false;
    });
    // THESE ARE ALL SYONYMS, But there are subtle semantics, that could be hooked via UX details
    // and are hooked on the server
    $(document).off('click', 'a.action-network-add-public');
    $(document).on('click', 'a.action-network-add-public', function(e){
        e.stopImmediatePropagation();
        dd007_addNetworkConnection(e, 'public');
        return false;
    });
    $(document).off('click', 'a.action-network-add-provider');
    $(document).on('click', 'a.action-network-add-provider', function(e){
        e.stopImmediatePropagation();
        dd007_addNetworkConnection(e, 'provider');
        return false;
    });
    $(document).off('click', 'a.action-network-add-private');
    $(document).on('click', 'a.action-network-add-private', function(e){
        e.stopImmediatePropagation();
        dd007_addNetworkConnection(e, 'private');
        return false;
    });
    $(document).off('click', 'a.action-network-accept-public');
    $(document).on('click', 'a.action-network-accept-public', function(e){
        e.stopImmediatePropagation();
        dd007_acceptNetworkConnection(e, 'public');
        return false;
    });
    $(document).off('click', 'a.action-network-accept-provider');
    $(document).on('click', 'a.action-network-accept-provider', function(e){
        e.stopImmediatePropagation();
        dd007_acceptNetworkConnection(e, 'provider');
        return false;
    });
    $(document).off('click', 'a.action-network-accept-private');
    $(document).on('click', 'a.action-network-accept-private', function(e){
        e.stopImmediatePropagation();
        dd007_acceptNetworkConnection(e, 'private');
        return false;
    });
    $(document).off('click', 'a.action-network-update-public');
    $(document).on('click', 'a.action-network-update-public', function(e){
        e.stopImmediatePropagation();
        dd007_updateNetworkConnection(e, 'public');
        return false;
    });
    $(document).off('click', 'a.action-network-update-provider');
    $(document).on('click', 'a.action-network-update-provider', function(e){
        e.stopImmediatePropagation();
        dd007_updateNetworkConnection(e, 'provider');
        return false;
    });
    $(document).off('click', 'a.action-network-update-private');
    $(document).on('click', 'a.action-network-update-private', function(e){
        e.stopImmediatePropagation();
        dd007_updateNetworkConnection(e, 'private');
        return false;
    });
});