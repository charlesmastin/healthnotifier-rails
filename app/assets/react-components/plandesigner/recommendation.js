import React from 'react';

var categories = [
  "Findings",
  "Treatment",
  "Precautions",
  "Work Restrictions",
  "School Restrictions",
  "Travel Restrictions",
  "Dietary Suggestions",
  "Follow Up"
];

const Recommendation = React.createClass({
    getInitialState: function(){
        return this.props.data;
    },
    handleRemove: function(e){
        $(document).trigger('onStoreChange', ['DELETE_RECOMMENDATION', {index: this.props.index}]);
        e.preventDefault();
    },
    handleAddComponent: function(e){
        // quick hack zone sone
        var s = this.state;
        s.components.push({
            category: '',
            data: ''
        });
        // TODO: temp until we use an action to update the store
        $(document).trigger('onStoreChange', ['UPDATE_RECOMMENDATION', {index: this.props.index, model: s}]);
        e.preventDefault();
    },
    handleRemoveComponent: function(e){
        // yea son dark pattern vs the whole dom parent.index() BSFL
        var s = this.state;
        s.components.splice(e.target.getAttribute('data-index'), 1);
        $(document).trigger('onStoreChange', ['UPDATE_RECOMMENDATION', {index: this.props.index, model: s}]);
        e.preventDefault();
    },
    handleComponentCategoryChange: function(e){
        var index = $(e.target).parent().parent().index() - 2; // component inside the stack, ghetto town
        var s = this.state;
        s.components[index].category = e.target.value;
        $(document).trigger('onStoreChange', ['UPDATE_RECOMMENDATION', {index: this.props.index, model: s}]);
    },
    handleComponentDataChange: function(e){
        var index = $(e.target).parent().parent().index() - 2; // component inside the stack, ghetto town
        var s = this.state;
        s.components[index].data = e.target.value;
        $(document).trigger('onStoreChange', ['UPDATE_RECOMMENDATION', {index: this.props.index, model: s}]);
    },
    handleUpdateName: function(e){
        var s = this.state;
        s.name = e.target.value;
        $(document).trigger('onStoreChange', ['UPDATE_RECOMMENDATION', {index: this.props.index, model: s}]);
    },
    handlePreview: function(e){
        var url = "/profiles/" + this.props.config.patient_uuid + "/advise-me/" + this.props.config.plan_uuid + "/advice/" + this.state.uuid;
        window.open(url, '_blank');
        e.preventDefault();
    },
    render: function(){
        var parent = this;
        // <a href="https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet" className="button small" target="_blank">Markdown cheatsheet</a>
        // base url is /profiles/patient.uuid/advise-me/careplan.uuid/advise/recommenation.uuid
        // /profiles/{this.props.config.patient_uuid}/advise-me/{this.props.config.plan_uuid}/advise/{this.state.uuid}
        return (
            <article className="recommendation">
                <header>
                    <h6>Recommendation-{this.props.index}: {this.state.uuid.substr(0, 8)}…</h6>
                    <div className="actions">
                        <a href="#" onClick={this.handlePreview}><i className="material-icons">launch</i></a>
                        <a href="#" className="button small" onClick={this.handleAddComponent}>Add Component</a>
                        <a href="#" className="button small" onClick={this.handleRemove}>Remove</a>
                    </div>
                </header>
                
                <div className="auth-form">
                    <div className="field">
                        <label>Name</label>
                        <input type="text" placeholder="Internal Name" value={this.state.name} onChange={this.handleUpdateName} />
                    </div>
                    <div className="field">
                        <h6>Components</h6>
                    </div>
                    {this.state.components.map(function(component, index) {
                        return (
                            <div key={index}>
                            <div className="field">
                                <label>Component</label>
                                <select value={component.category} onChange={parent.handleComponentCategoryChange}>
                                    <option value="" key="-1"></option>
                                    {categories.map(function(category, index) {
                                        return <option value={category} key={index}>{category}</option>;
                                    })}
                                </select>
                                <a href="#" className="button small" data-index={index} onClick={parent.handleRemoveComponent}>Remove</a>
                            </div>
                            <div className="field">
                                <label>Content</label>
                                <textarea value={component.data} placeholder="Markdown content here" onChange={parent.handleComponentDataChange}></textarea>
                            </div>
                            </div>
                        )
                    })}
                </div>
                <a href="#" className="button small" onClick={this.handleAddComponent}>Add Component</a>
            </article>
        )
    }
});

export default Recommendation;