import React from 'react';

import FilterAge from './filter-age';
import FilterAllergy from './filter-allergy';

// open up and submit for persist state, but while editing use local state, ok mmkay

const Filters = React.createClass({
    getInitialState: function(){
        return this.props.data;
    },
    handleModeChange: function(){

    },
    handleRemoveFilter: function(){

    },
    addFilter: function(){

    },
    render: function(){
        return (
            <div className="plan-filters">
                <h4>FILTERS SON</h4>
                <select value={this.state.mode} onChange={this.handleModeChange}>
                    <option value="and">AND</option>
                    <option value="or">OR</option>
                </select>
                <ul>
                    {this.state.parameters.map(function(obj, index) {
                        return (
                        <li key={index}>
                            <label>Not <input type="checkbox" /></label>
                            <a href="#" onClick={parent.handleRemoveFilter} className="button small">Remove</a>
                            <FilterAge index={index} data={obj} />
                        </li>
                        )
                    })}
                    // filter shell
                    // inner gut component
                </ul>
                <a href="#" className="button" onClick={this.addFilter}>Add Filter</a>
            </div>
        )
    }
});

export default Filters;         