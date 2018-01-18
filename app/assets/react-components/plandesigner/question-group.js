import React from 'react';
import QuestionEditor from './question-editor';
import { uuid } from './utils';

const QuestionGroup = React.createClass({
    getInitialState: function(){
        return this.props.data;
    },
    handleAddQuestion: function(e){
        var model = {uuid: uuid(), name: '', choices: [], choice_type: ''};
        var s = this.state;
        s.questions.push(model);
        $(document).trigger('onStoreChange', ['UPDATE_GROUP', {index: this.props.index, model: s}]);
        e.preventDefault();
    },
    callbackHandleUpdateQuestion: function(id, data){
        var s = this.state, index = 0;
        s.questions.forEach(function(item, ind){
            if(item.id == id){
                index = ind;
            }
        });
        if(data == undefined){
            s.questions.splice(index, 1);
        }else {
            s.questions.splice(index, 1, data);    
        }
        $(document).trigger('onStoreChange', ['UPDATE_GROUP', {index: this.props.index, model: s}]);
    },
    handleRemoveGroup: function(e){
        this.props.parent.handleRemoveGroup(this.props.index);
        e.preventDefault();
    },
    handleInsertGroup: function(e){
        // blablablablablblablablablabla
        var index = $(e.target).parent().parent().index();
        $(document).trigger('onStoreChange', ['CREATE_GROUP', {index: index}]);

        e.preventDefault();
    },
    handleInlineTriggerCreate: function(question_index, choice_index, val){
        // ok coming down from a trigger inside a "choice" inside a "question"
        // trigger -> question -> this
        // yup this is working
        // ok so now we're aware of all the context, but how to we handle it, probably up in the plan-editor.js, probably
        var trigger_origin = {
            group_uuid: this.state.uuid,
            question_index: question_index,
            choice_index: choice_index,
            type: val
        }
        if(val == 'new-group'){
            $(document).trigger('onStoreChange', ['CREATE_GROUP', {index:this.props.index+1, trigger_origin: trigger_origin}]); // somehow send an index that is +1 from current or current
        }
        if(val == 'new-recommendation'){
            $(document).trigger('onStoreChange', ['CREATE_RECOMMENDATION', {index:0, trigger_origin: trigger_origin}]);
        }
    },
    componentDidMount: function(){
        // anti patterns sans flux / redux
    },
    componentWillUnmount: function(){
        // anti patterns sans flux / redux
    },

    // TODO: default trigger to the next question or to the recommendations
    // this depends on the state of the children, and would be better served as some computed model method
    // redux yourselfsilly
    // <QuestionSummary style="display: none;" key="summary-{index}" data={question} />
    render : function(){

        var parent = this;

        return (
            <span>
            <section className="question-group">
            <header>
                <h6>Group-{this.props.index}: {this.props.data.uuid.substr(0, 8)}…</h6>
                <div className="actions">
                <a href="#" className="button small" onClick={this.handleAddQuestion} >Add Question</a>
                <a href="#" className="button small" onClick={this.handleRemoveGroup} >Remove</a>
                </div>
            </header>


            {this.props.data.questions.map(function(question, index) {
                return (
                <QuestionEditor index={index} updateFunc={parent.callbackHandleUpdateQuestion} inlineCreateFunc={parent.handleInlineTriggerCreate} key={question.uuid} data={question} availableGroups={parent.props.data.available_groups} availableRecommendations={parent.props.data.available_recommendations} />
                )
            })}
            </section>
            <div className="insert-group"><a href="#" className="button small" onClick={this.handleInsertGroup}>Add Group</a></div>
            </span>
        )
    }
});

export default QuestionGroup;