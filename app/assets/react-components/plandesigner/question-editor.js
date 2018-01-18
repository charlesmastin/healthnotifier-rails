import React from 'react';
import TriggerEditor from './trigger-editor';
import { uuid } from './utils';

const QuestionEditor = React.createClass({
    getInitialState: function(){
        return this.props.data;
    },
    handleNameChange: function(e){
        var s = this.state;
        s.name = e.target.value;
        this.props.updateFunc(s.id, s);
    },
    handleChoiceTypeChange: function(e){
        var s = this.state;
        s.choice_type = e.target.value;
        // pre-fill Y/N on virgin bits
        if(s.choices.length == 0){
            if(s.choice_type == 'YES_NO'){
                s.choices.push({name: 'Yes', uuid: uuid()});
                s.choices.push({name: 'No', uuid: uuid()});
            }
            if(s.choice_type == 'SINGLE_ANSWER'){
                s.choices.push({name: 'Choice 1', uuid: uuid()});
                s.choices.push({name: 'Choice 2', uuid: uuid()});
                s.choices.push({name: 'Choice 3', uuid: uuid()});
            }
            if(s.choice_type == 'MULTI_ANSWER'){
                s.choices.push({name: 'Choice 1', uuid: uuid()});
                s.choices.push({name: 'Choice 2', uuid: uuid()});
                s.choices.push({name: 'Choice 3', uuid: uuid()});
            }
        }
        this.props.updateFunc(s.id, s);
        e.preventDefault();
        // this.setState({choice_type: e.target.value});
    },
    handleDestroy: function(e){
        this.props.updateFunc(this.state.id);
        e.preventDefault();
    },
    handleRemoveChoice: function(e){
        var index = $(e.target).parent().index();
        var removed = this.state.choices.splice(index, 1);
        this.props.updateFunc(this.state.id, this.state);
        e.preventDefault();
    },
    handleAddChoice: function(e){
        var s = this.state;
        s.choices.push({uuid: uuid()});
        this.props.updateFunc(s.id, s);
        e.preventDefault();
    },
    handleChoiceChange: function(e){
        // if we were so inclined, we would just make this here a component as well, why not
        var index = $(e.target).parent().index();
        var s = this.state;
        s.choices[index].name = e.target.value;
        this.props.updateFunc(s.id, s);
    },
    callbackHandleAddTrigger: function(index){
        var s = this.state;
        // TODO: clarity here, this is the original case, and the one where uuid is really target_uuid, vs the uuid
        // that said, Trigger objects are virtual so whatevs
        s.choices[index].trigger = {uuid: '', type: 'group'};
        this.props.updateFunc(s.id, s);
    },
    callbackHandleUpdateTrigger: function(index, data){
        // this is the add and remove
        var s = this.state;
        if(data != undefined){
            s.choices[index].trigger = data;
        }else {
            // delete it :)
            s.choices[index].trigger = undefined;
        }
        this.props.updateFunc(s.id, s);
    },
    callbackCreateInline: function(index, val){
        this.props.inlineCreateFunc(this.props.index, index, val);
    },
    render: function(){
        /*
        <a href="#" className="button small">Pre-selection</a>
        <a href="#" className="button small">Visibility Filter</a>
        */
        var parent = this;
        return (
            <div className="question-editor">
                <header>
                    <div><small>Question: {this.state.uuid.substr(0, 8)}…</small> <a href="#" onClick={this.handleDestroy} className="button small">Remove</a></div>
                    <textarea placeholder="Question in plain text goes here for you to enter things. Or does it?" x-value={this.state.name} onChange={this.handleNameChange} rows="2">{this.state.name}</textarea>
                    
                </header>
                <div className="auth-form">
                <div className="field">
                <label>Response Type</label>
                <select name="" value={this.state.choice_type} onChange={this.handleChoiceTypeChange}>
                    <option value=""></option>
                    <option value="YES_NO">YES/NO</option>
                    <option value="SINGLE_ANSWER">SINGLE</option>
                    <option value="MULTI_ANSWER" disabled="disabled">MULTIPLE</option>
                </select>
                </div>
                </div>
                <ul className="choices basic">
                    {this.state.choices.map(function(choice, index) {
                        return (
                        <li key={index}>
                            <input type="text" value={choice.name} onChange={parent.handleChoiceChange} />
                            <a href="#" onClick={parent.handleRemoveChoice} className="button small">Remove</a>
                            <TriggerEditor index={index} inlineCreateFunc={parent.callbackCreateInline} addFunc={parent.callbackHandleAddTrigger} updateFunc={parent.callbackHandleUpdateTrigger} data={choice} availableGroups={parent.props.availableGroups} availableRecommendations={parent.props.availableRecommendations} />
                        </li>
                        )
                    })}
                    <li><a href="#" className="button zprimary small" onClick={this.handleAddChoice} >Add Choice</a></li>
                </ul>
            </div>
        )
    }
});

QuestionEditor.propTypes = {
    updateFunc: React.PropTypes.func,
    inlineCreateFunc: React.PropTypes.func,
    index: React.PropTypes.number
}

export default QuestionEditor
