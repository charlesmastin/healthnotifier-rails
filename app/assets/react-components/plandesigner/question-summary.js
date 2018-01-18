import React from 'react';
import TriggerSummary from './trigger-summary';

const QuestionSummary = React.createClass({

    getInitialState: function(){
        return {name: ''}
    },

    handleChange: function(e) {
        this.setState({ name: e.target.value });
    },

    render: function(){

        // convenience fillter for Y/N

        // THIS IS OVER THE TOP? NO?
        let choicesDom;
        if(this.props.data.chocies != undefined && this.props.data.choices.length){
            var bla = [];
            this.props.data.choices.forEach(v => {
                bla.push(v.name);
            });
            choicesDom = (<div className="choices">{bla.join(', ')}</div>)
        }

        let triggersDom;
        let triggerNodes = [];
        // this is JW so we don't render a blank wrapper BLA BLABLABLA
        if(this.props.data.choices){
            this.props.data.choices.forEach(v => {
                if(v.trigger != undefined){
                    triggerNodes.push(true);
                    // break;
                }
            });
            
            if(triggerNodes.length){
                triggersDom = (
                <div className="triggers">
                    <ul className="basic">
                        {this.props.data.choices.map(function(choice, index) {
                            if(choice.trigger != undefined){
                                return <TriggerSummary key={index} data={choice}/>;
                            }
                        })}
                    </ul>
                </div>
                )
            }
        }

        return (
            <div>
                <h3>{this.props.data.name}<span className="tag">{this.props.data.choice_type}</span></h3>
                {choicesDom}
                {triggersDom}
            </div>
        );
    } 
});

export default QuestionSummary;