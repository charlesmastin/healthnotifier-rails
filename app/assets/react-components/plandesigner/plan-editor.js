import React from 'react';
import update from 'react-addons-update';

import QuestionGroup from './question-group';
import Recommendation from './recommendation';
import Filters from './filters';

import { uuid, mergeDeep } from './utils';

const PlanEditor = React.createClass({
    getInitialState: function(){
        // non abuse case, setting initial data
        return this.props.data;
    },
    handleUndo: function(e){
        e.stopImmediatePropagation();
        if(this.undo_history.length){
            //var s = this.undo_history.pop();
            //console.log('retrieving', s);
            // this.setState(s);
            //this.setState(update(this.state, {$merge: s}));
        }
        // generally a fail
    },
    handleRedo: function(e){
        e.stopImmediatePropagation();
        // FAIL
    },
    handleStatusChange: function(e){
        $(document).trigger('onStoreChange', ['UPDATE_PLAN', {status: e.target.value}]);
        e.preventDefault();
    },
    handleNameChange: function(e){
        $(document).trigger('onStoreChange', ['UPDATE_PLAN', {name: e.target.value}]);
        e.preventDefault();
    },
    handleOrgChange: function(e){
        $(document).trigger('onStoreChange', ['UPDATE_PLAN', {organization_id: parseInt(e.target.value, 10)}]);
        e.preventDefault();
    },
    handleFilterChange: function(e){
        $(document).trigger('onStoreChange', ['UPDATE_PLAN', {filter_id: e.target.value}]);
        // if custom, show the custom input UI or is that coded in some reactive way, in the render, probably. ,blbalbaablabla
        e.preventDefault();
    },
    handleRecommendationChange: function(e){
        // ghetto strap it, deep divers
        $(document).trigger('onStoreChange', ['UPDATE_PLAN', {recommendation: {text: e.target.value}}]);
        e.preventDefault();
    },
    handleAddGroup: function(e){
        $(document).trigger('onStoreChange', ['CREATE_GROUP', {index:0}]);
        e.preventDefault();
    },
    handleRemoveGroup: function(index){
        $(document).trigger('onStoreChange', ['DELETE_GROUP', {index:index}]);
    },
    handleAddRecommendation: function(e){
        $(document).trigger('onStoreChange', ['CREATE_RECOMMENDATION', {index:0}]);
        e.preventDefault();
    },
    handleRemoveRecommendation: function(index){
        $(document).trigger('onStoreChange', ['DELETE_RECOMMENDATION', {index:index}]);
    },
    // special inline creator guys
    handleCreateInlineTriggerGroup: function(e, data){

    },
    handleCreateInlineRecommendationGroup: function(e, data){

    },
    onSave: function(e){
        e.stopImmediatePropagation();
        // AKA validate your steeze
        // aka time for legit validations library up in here son
        if(this.state.name == undefined || this.state.name == ''){
            window.app.alert('Please input plan name', function(){
                // LOLO YOLO SON
                setTimeout(function(){
                    document.getElementById('plan-name').focus();
                }, 100);
            });
            return;
        }
        // this is not nullable, so just deal with it
        if(this.state.organization_id == undefined){
            window.app.alert('Please select organization', function(){
                // LOLO YOLO SON
                setTimeout(function(){
                    document.getElementById('plan-organization').focus();
                }, 100);
            });
            return;
        }
        // min 1 question group
        if(this.state.status == 'ACTIVE' && this.state.groups.length == 0){
            window.app.alert('Please add at least one question group');
            return;
        }
        // min 1 recommendation - matters if active is true, otherwise, it's OK son
        if(this.state.status == 'ACTIVE' && this.state.recommendations.length == 0){
            window.app.alert('Please add at least one recommendation');
            return;
        }

        // validate the children components YEA SON

        // TODO: scrub that shiz down son, strip out da nested available_groups, available_recommendations
        
        $(document).trigger('onCarePlanSave', [this.state]);
    },
    onCancel: function(e, url){
        e.stopImmediatePropagation();
        if(this.undo_history.length){
            app.confirm(
                {
                    title: "Cancel Editing?",
                    text: "You have unsaved changes…",
                    type: "warning",
                    showCancelButton: true,
                    allowOutsideClick: true,
                    cancelButtonText: "Continue Editing",
                    confirmButtonText: "Disregard Changes"
                },
                function(){
                    window.location = url;
                }
            );
        }else{
            window.location = url;
        }
    },
    pluginGroupState: function(group){
        // obtain a simplified list of available groups and recommendations and pass down
        group.available_groups = [];
        group.available_recommendations = [];

        for(let [index, value] of this.state.groups.entries()){
            var obj = {
                uuid: value.uuid,
                name: 'Group-' + index
            }
            obj.display = obj.name + ': ' + value.uuid.substring(0, 8) + '…';
            group.available_groups.push(obj);
        }

        for(let [index, value] of this.state.recommendations.entries()){
            var obj = {
                uuid: value.uuid,
                name: 'Recommendation-' + index
            }
            if(value.name != ''){
                obj.name = value.name;
            }
            obj.display = obj.name + ': ' + value.uuid.substring(0, 8) + '…';
            group.available_recommendations.push(obj);
        }

        return group;
    },
    pluginInlineTriggerReducer: function(model, payload){
        var s = this.state;
        var g = undefined;
        // TODO: use some badass search pluck babababa es6 FML BRAIN NO WORKY WORK
        for(var i=0;i<s.groups.length;i++){
            if(s.groups[i].uuid == payload.trigger_origin.group_uuid){
                g = s.groups[i];
                break;
            }
        }
        if(g != undefined){
            g.questions[payload.trigger_origin.question_index].choices[payload.trigger_origin.choice_index].trigger = {
                uuid: model.uuid,
                type: payload.trigger_origin.type.substr(4)
            }
            $(document).trigger('onStoreChange', ['UPDATE_PLAN', {groups: s.groups}]);
        }
    },
    handleStoreChange: function(e, action, payload){
        // and push the current state into the history???? lolzors
        // be careful to destroy all "future state" when making any actual changes
        // hook in da deep dive cloners here to make this work, lul
        // testing all contendors, and immutable js directly (although it has some overhead)
        // let clone = Object.assign({}, this.state);
        //let clone = mergeDeep({}, this.state);
        
        // why not
        e.stopImmediatePropagation();

        this.undo_history.push('DONKEY');
        var scope = this;
        var stateCallback = null;
        // redux store and built in reducer lolzors
        switch(action){
            case 'CREATE_GROUP':
                var model = {uuid: uuid(), name: null, description: null, questions: [
                    {uuid: uuid(), name: '', choices: [], choice_type: ''}
                ]};
                if(payload.trigger_origin != undefined){
                    stateCallback = function(){
                        scope.pluginInlineTriggerReducer(model, payload)
                    }
                }
                // ok, lol we only have one possible argument to add, so let's not be "fancy" with call/apply
                var nextState = {groups: update(this.state.groups, {$splice: [[payload.index, 0, model]]}) };
                if(stateCallback){
                    this.setState(nextState, stateCallback);
                }else{
                    this.setState(nextState);
                }
            break;

            case 'UPDATE_GROUP':
                this.setState({groups: update(this.state.groups, {$splice: [[payload.index, 1, payload.model]]}) });
            break;

            case 'DELETE_GROUP':
                this.setState({groups: update(this.state.groups, {$splice: [[payload.index, 1]]}) });
            break;

            case 'UPDATE_PLAN':
                // AKA UPDATE the entire mambo jambo
                // given what's passed in, set it and do the magic, because this will be in the "store"
                this.setState(update(this.state, {$merge: payload}));
            break;

            case 'CREATE_RECOMMENDATION':
                var model = {uuid: uuid(), name: null, description: null, components: []};
                if(payload.trigger_origin != undefined){
                    stateCallback = function(){
                        scope.pluginInlineTriggerReducer(model, payload)
                    }
                }
                // ok, lol we only have one possible argument to add, so let's not be "fancy" with call/apply
                var nextState = {recommendations: update(this.state.recommendations, {$push: [model]}) }
                if(stateCallback){
                    this.setState(nextState, stateCallback);
                }else{
                    this.setState(nextState);
                }
            break;

            case 'DELETE_RECOMMENDATION':
                // TODO: handle the cascade of anything currently using this module
                this.setState({recommendations: update(this.state.recommendations, {$splice: [[payload.index, 1]]}) });
            break;

            case 'UPDATE_RECOMMENDATION':
                this.setState({recommendations: update(this.state.recommendations, {$splice: [[payload.index, 1, payload.model]]}) });
            break;

            // TODO: decide if UNDO/REDO need to be in here, meh

            default:

            break;
        }
    },
    componentWillMount: function(){
        this.undo_history = [];
    },
    componentDidMount: function(){
        // so… yea, an immutible copy?
        // this.undo_history.push(this.state);
        // internal FLUX replacement store action handler
        // WAY WAY WAY OVER THE TOP UNBINDING
        $(document).off('onStoreChange', this.handleStoreChange);
        $(document).on('onStoreChange', this.handleStoreChange);
        // EXTERNAL from Rails Container and inline js (backbone, whatever)
        // WAY WAY WAY OVER THE TOP UNBINDING
        $(document).off('onDesignerSave', this.onSave);
        $(document).off('onDesignerCancel', this.onCancel);
        $(document).off('onDesignerUndo', this.handleUndo);
        $(document).off('onDesignerRedo', this.handleRedo);
        // yup
        $(document).on('onDesignerSave', this.onSave);
        $(document).on('onDesignerCancel', this.onCancel);
        $(document).on('onDesignerUndo', this.handleUndo);
        $(document).on('onDesignerRedo', this.handleRedo);
    },
    componentWillUnmount: function(){
        // this prevents a clogging of the event delegation bus when navigation to and from parent route
        // anti patterns sans flux / redux
        $(document).off('onStoreChange', this.handleStoreChange);
        // EXTERNAL from Rails Container and inline js (backbone, whatever)
        $(document).off('onDesignerSave', this.onSave);
        $(document).off('onDesignerCancel', this.onCancel);
        $(document).off('onDesignerUndo', this.handleUndo);
        $(document).off('onDesignerRedo', this.handleRedo);
    },
    render: function(){
        var parent = this;
        var recommendation_config = {
            patient_uuid: this.props.patient_uuid,
            plan_uuid: this.state.uuid // TODO: initial case coming from server, blablabal, init somewhere son just because the route is a tingly ducker
        }
        return (
            <span>
            <div className="auth-form">
            <div className="row floated-elements">
            <div className="field">
                <label>Publish State</label>
                <select id="plan-status" name="" value={this.state.status} onChange={this.handleStatusChange}>
                    <option value="DRAFT">Draft</option>
                    <option value="ACTIVE">Active</option>
                    <option value="DELETED" disabled="disabled">Deleted</option>
                </select>
            </div>
            
            <div className="field">
                <label>Organization</label>
                <select id="plan-organization" name="" value={this.state.organization_id} onChange={this.handleOrgChange}>
                    <option value="" key="-1"></option>
                    {this.props.config.organizations.map(function(org, index) {
                        return <option value={org[1]} key={org[1]}>{org[0]}</option>;
                    })}
                </select>
            </div>
            
            </div>

            <div className="row">
                <Filters data={this.props.config.plan_filters}/>
            </div>

            <div className="field">
                <label>Name</label>
                <input id="plan-name" type="text" value={this.state.name} placeholder="Descriptive Condition Name" onChange={this.handleNameChange} />
            </div>

            </div>
            <h3>Questions</h3>
            <section className="question-groups">
            <div className="insert-group"><a href="#" className="button small" onClick={this.handleAddGroup}>Add Group</a></div>
            {this.state.groups.map(function(group, index) {
                // because I don't know the most architecturally sound way to do this,
                // act like a plugin and modify the data going in in the parent scope where we have access to the entire state, but only here
                return <QuestionGroup parent={parent} key={group.uuid} index={index} data={parent.pluginGroupState(group)}/>;
            })}
            </section>
            <hr />
            <h3>Recommendations</h3>
            <section className="recommendations">
            {this.state.recommendations.map(function(recommendation, index) {
                return <Recommendation parent={parent} key={recommendation.uuid} index={index} data={recommendation} config={recommendation_config} />;
            })}
            </section>
            <div className="insert-group"><a href="#" className="button small" onClick={this.handleAddRecommendation}>Add Recommendation</a></div>
            </span>
        );
    } 
});

export default PlanEditor;