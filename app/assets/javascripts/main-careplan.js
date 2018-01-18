// ES6 entry point bootstrapper for careplan (app)
// import { AppContainer } from 'react-hot-loader';
import React from 'react';
import ReactDOM from 'react-dom';

import PlanEditor from './../react-components/plandesigner/plan-editor';

// howto import all my stizzle
var rootElement = document.getElementById('react-dingle-dongle');

ReactDOM.render(
    <PlanEditor data={window.CAREPLAN_MODEL} config={window.CAREPLAN_CONFIG} />,
    rootElement
);
/*
if (module.hot) {
  module.hot.accept('./../react-components/plandesigner/plan-editor', () => {
    ReactDOM.render(
      <AppContainer><PlanEditor data={window.CAREPLAN_MODEL} config={window.CAREPLAN_CONFIG} /></AppContainer>,
      rootElement
    );
  });
}
*/