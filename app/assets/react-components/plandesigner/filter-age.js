import React from 'react';
const FilterAge = React.createClass({
    render: function(){
        return (
            <div>Age is between <input type="number" value="18" /> and <input type="number" value="21" /></div>
        )
    }
});

export default FilterAge;