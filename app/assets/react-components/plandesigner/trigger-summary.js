import React from 'react';
const TriggerSummary = React.createClass({
    render: function(){
        return (
            <li>If <strong>{this.props.data.name}</strong> Jump To <strong>Group: {this.props.data.trigger.group}</strong></li>
        )
    }
});

export default TriggerSummary;

/*
<div class="triggers aggregate">
    <ul class="basic">
        <li>Any Responses Jump To <strong>Recommendations</strong></li>
    </ul>
</div>
*/