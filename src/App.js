import React, { Fragment } from 'react';
import './App.css';
import BuildHistoryDisplay from './BuildHistoryDisplay.js';
import { BrowserRouter as Router, Route, Link } from "react-router-dom";

const App = () => (
  <Router basename={process.env.PUBLIC_URL + '/'}>
    <div className="App">
      <header className="App-header">
        <h1 className="App-title"><Link to="/">Pytorch nightly builds HUD</Link> (<a href="https://github.com/pytorch/builder/tree/gh-pages">GitHub</a>)</h1>
      </header>
      <Route path="/" component={BuildRoute} />
    </div>
  </Router>
);

const Home = () => (
  <div>
    <BuildHistoryDisplay interval={60000}/>
  </div>
);

const Build = ({ match }) => {
  // Uhhh, am I really supposed to rob window.location here?
  const query = new URLSearchParams(window.location.search);
  return <BuildHistoryDisplay interval={60000} />
};

const BuildRoute = ({ match }) => (
  <Fragment>
    <Route exact path={match.url} component={Build} />
    <Route path={`${match.url}/:segment`} component={BuildRoute} />
  </Fragment>
);

export default App;
