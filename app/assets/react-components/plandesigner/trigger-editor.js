import React from 'react';

const TriggerEditor = React.createClass({
    handleChange: function(e){
        var state = this.props.data.trigger;
        // but son peep it up in here
        var val = e.target.value;
        if(val != 'new-group' && val != 'new-recommendation'){
            state.uuid = val;
            state.type = e.target.getAttribute("data-type")
            this.props.updateFunc(this.props.index, state);
        }else{
            this.props.inlineCreateFunc(this.props.index, val);
            // i am complicated
        }
        
        e.preventDefault();
    },
    handleAdd: function(e){
        this.props.addFunc(this.props.index);
        e.preventDefault();
    },
    handleRemove: function(e){
        this.props.updateFunc(this.props.index);
        e.preventDefault();
    },
    render: function(){
        if(this.props.data.trigger != undefined){
        return (
            <div className="trigger-editor triggersz">
                Jump to

                <select className="monospaced" value={this.props.data.trigger.uuid} onChange={this.handleChange}>
                    <option value="" key="-1"></option>
                    <optgroup label="Question Group">
                        {this.props.availableGroups.map(function(object, index) {
                        return <option value={object.uuid} data-type="group" key={"group-" + index}>{object.display}</option>;
                        })}
                        <option value="new-group">+ New Group</option>
                    </optgroup>
                    <optgroup label="Recommendation">
                        {this.props.availableRecommendations.map(function(object, index) {
                        return <option value={object.uuid} data-type="recommendation" key={"recommendation-" + index}>{object.display}</option>;
                        })}
                        <option value="new-recommendation">+ New Recommendation</option>
                    </optgroup>
                </select>

                <a href="#" onClick={this.handleRemove}><i className="material-icons">remove_circle</i></a>
            </div>
        )
        } else {
        return <a href="#" onClick={this.handleAdd} className="button small">Add Trigger</a>
        }
    }
})

TriggerEditor.propTypes = {
    updateFunc: React.PropTypes.func,
    addFunc: React.PropTypes.func,
    index: React.PropTypes.number,
    inlineCreateFunc: React.PropTypes.func
}

export default TriggerEditor;