import thunk from 'redux-thunk';
import rootReducer from './rootReducer.js';
import {stateHistoryTracker as trackHistory } from 'redux-state-history/lib/stateHistory';
import {
  applyMiddleware,
  compose,
  createStore

}from 'redux';

export default function configureStore (initialState) {
  let createStoreWithMiddleware;
  const middleware = applyMiddleware(thunk);
  createStoreWithMiddleware = compose(middleware, trackHistory());

  const store = createStoreWithMiddleware(createStore)(
    rootReducer, initialState
  );
  return store;
}
