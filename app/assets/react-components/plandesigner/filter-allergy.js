import React from 'react';
const FilterAllergy = React.createClass({
    render: function(){
        return (
            <div>Allergy is <input type="text" className="autocomplete" value="Bee Sting" /> (w/ reaction of y)</div>
        )
    }
});

export default FilterAllergy;