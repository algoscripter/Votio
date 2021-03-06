import Header from 'components/Header';
import Flash from 'components/Flash';
export default class CoreLayout extends React.Component {
  static propTypes = {
    children : React.PropTypes.element
  };

  render () {
    return (
      <div className='container'>
        <Header />
        <Flash />
        <div className='view-container'>
          {this.props.children}
        </div>
      </div>
    );
  }
}
