import React, { Component } from 'react'
import supplyChainEPContract from '../build/contracts/SupplyChainEP.json'
import getWeb3 from './utils/getWeb3'

import './css/oswald.css'
import './css/open-sans.css'
import './css/pure-min.css'
import './App.css'

// TODO: Do I need to link strings library here too?

class App extends Component {
  constructor(props) {
    super(props)

    this.state = {
      parts: "",
      web3: null,
      contract: null,
      account: null,
      newPartString: "",
      newSubpartString: "",
      newWhitelistPart:"",
      newWhitelistUser: null,
      newNotifyPart:"",
      newNotifyIPFS:""
    }

    this.handleChangePart = this.handleChangePart.bind(this);
    this.handleChangeSubpart = this.handleChangeSubpart.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.handleChangeWhitelistPart = this.handleChangeWhitelistPart.bind(this);
    this.handleChangeWhitelistUser = this.handleChangeWhitelistUser.bind(this);
    this.handleWhitelistSubmit = this.handleWhitelistSubmit.bind(this);
    this.handleChangeNotifyPart = this.handleChangeNotifyPart.bind(this);
    this.handleChangeNotifyIPFS = this.handleChangeNotifyIPFS.bind(this);
    this.handleNotifySubmit = this.handleNotifySubmit.bind(this);
    this.handleReceiveNotification = this.handleReceiveNotification.bind(this);
    this.handleUpdateAccount = this.handleUpdateAccount.bind(this);
  }

  componentWillMount() {
    // Get network provider and web3 instance.
    // See utils/getWeb3 for more info.

    getWeb3
    .then(results => {
      this.setState({
        web3: results.web3
      })

      // Instantiate contract once web3 provided.
      this.instantiateContract()
    })
    .catch(() => {
      console.log('Error finding web3.')
    })
  }

  instantiateContract() {
    /*
     * SMART CONTRACT EXAMPLE
     *
     * Normally these functions would be called in the context of a
     * state management library, but for convenience I've placed them here.
     */

    const contract = require('truffle-contract')
    const supplyChainEP = contract(supplyChainEPContract)
    supplyChainEP.setProvider(this.state.web3.currentProvider)

    // Declaring this for later so we can chain functions on SimpleStorage.
    var supplyChainEPInstance
    // Get accounts.
    this.state.web3.eth.getAccounts((error, accounts) => {
      supplyChainEP.deployed().then((instance) => {
        supplyChainEPInstance = instance
        return supplyChainEPInstance.myResources.call({from:accounts[0]})
      }).then((result) => {
        

        let resourceAddedEvent = supplyChainEPInstance.resourceAdded();
        resourceAddedEvent.watch((err, res) => {
          console.log(err);
          console.log(res);
        })

        let userWhitelistedEvent = supplyChainEPInstance.userWhitelisted();
        userWhitelistedEvent.watch((err, res) => {
          console.log(err);
          console.log(res);
        })

        let requestSentEvent = supplyChainEPInstance.requestSent();
        requestSentEvent.watch((err, res) => {
          console.log(err);
          console.log(res);
        })

        let warningSentEvent = supplyChainEPInstance.warningSent();
        warningSentEvent.watch((err, res) => {
          console.log(err);
          console.log(res);
        })

        this.setState({
          parts: result,
          web3: this.state.web3,
          contract: supplyChainEPInstance,
          account: accounts[0]
        });

        this.handleUpdateAccount()
      })
    })
  }

  handleUpdateAccount() {
    var self = this
    setInterval(function() {
      const newAccount = self.state.web3.eth.accounts[0]
      const currAccount = self.state.account
      if (newAccount !== currAccount) {
        self.setState({account: newAccount});
        console.log("Account updated to: " + newAccount)
      }
    }, 100);
  }

  handleSubmit(event){
    const contract = this.state.contract
    const account = this.state.account
    alert('A part was submitted: ' + this.state.newPartString + ' with subparts: ' + this.state.newSubpartString + ' for account: ' + account);
    event.preventDefault();

    contract.addResource(this.state.newPartString, this.state.newSubpartString, {from: account})
      .then(result => {
        this.setState({newPartString: ""});
        this.setState({newSubpartString: ""});
      })
  }

  handleChangeNotifyPart(event){
    this.setState({newNotifyPart: event.target.value});
    console.log(this.newNotifyPart)
  }

  handleChangeNotifyIPFS(event){
    this.setState({newNotifyIPFS: event.target.value});
  }

  handleNotifySubmit(event){
    alert("Sending Notification for part: " + this.state.newNotifyPart + "\n with IPFS: " + this.state.newNotifyIPFS + "\n with sending address: "
      + this.state.account)
    const contract = this.state.contract
    const account = this.state.account
    event.preventDefault();
    contract.notify(this.state.newNotifyPart, this.state.newNotifyIPFS, {from: account, value: this.state.web3.toWei('1', 'ether')})
      .then(result => {
        this.setState({newNotifyPart: ""});
        this.setState({newNotifyIPFS: ""});
      })
  }

  handleChangeWhitelistPart(event){
    this.setState({newWhitelistPart: event.target.value});
    console.log(this.newWhitelistPart)
  }

  handleChangeWhitelistUser(event){
    this.setState({newWhitelistUser: event.target.value});
  }

  handleWhitelistSubmit(event){
    const contract = this.state.contract
    const account = this.state.account
    alert("Trying to submit user: " + this.state.newWhitelistUser
     + "\n for part: " + this.state.newWhitelistPart
     + "\n from user: " + account)
    event.preventDefault();
    contract.whitelistUser(this.state.newWhitelistPart, this.state.newWhitelistUser, true, {from: account})
      .then(result => {
        this.setState({newWhitelistPart: ""});
        this.setState({newWhitelistUser: null})
    })
  }

  handleChangePart(event){
    this.setState({newPartString: event.target.value});
  }

  handleChangeSubpart(event){
    this.setState({newSubpartString: event.target.value});
  }

  handleReceiveNotification(event){
    const contract = this.state.contract
    const account = this.state.account
    event.preventDefault();
    contract.getRequests
      .call({from: account, gas: 100000})
      .then(result => {
        console.log(result)
        contract.getRequests({from: account, gas: 100000})
          .then(result => {
            console.log(result)
        })
    })
    // contract.getRequests({from: account, gas: 100000})
    //       .then(result => {
    //         console.log(result)
    //     })
  }

  render() {

    return (
      <div className="App">
        <nav className="navbar pure-menu pure-menu-horizontal">
            <a href="#" className="pure-menu-heading pure-menu-link">Truffle Box</a>
        </nav>

        <main className="container">
          <div className="pure-g">
            <div className="pure-u-1-1">
              <h1>Good to Go!</h1>
              <p>Your Truffle Box is installed and ready.</p>
              <h2>Smart Contract Example</h2>
              <p>If your contracts compiled and migrated successfully, below will show a stored value of 5 (by default).</p>
              <p>Try changing the value stored on <strong>line 59</strong> of App.js.</p>
              <p> Your parts are: {this.state.parts}</p>
              <form onSubmit={this.handleSubmit}>
                <label>
                  New Part Name:
                  <input type="text" value={this.state.value} onChange={this.handleChangePart} />
                </label>
                <label>
                  New Part Subparts:
                  <input type="text" value={this.state.value} onChange={this.handleChangeSubpart} />
                </label>
                <input type="submit" value="Submit" />
              </form>
              <form onSubmit={this.handleWhitelistSubmit}>
                <label>
                  Part Name for Whitelisting:
                  <input type="text" value={this.state.value} onChange={this.handleChangeWhitelistPart} />
                </label>
                <label>
                  User to whitelist (please enter address):
                  <input type="text" value={this.state.value} onChange={this.handleChangeWhitelistUser} />
                </label>
                <input type="submit" value="Submit" />
              </form>
              <form onSubmit={this.handleNotifySubmit}>
                <label>
                  Notify for part name:
                  <input type="text" value={this.state.value} onChange={this.handleChangeNotifyPart} />
                </label>
                <label>
                  IPFS Address:
                  <input type="text" value={this.state.value} onChange={this.handleChangeNotifyIPFS} />
                </label>
                <input type="submit" value="Submit" />
              </form>
              <button onClick={this.handleReceiveNotification}>Receive Notifications</button>
            </div>
          </div>
        </main>
      </div>
    );
  }
}

export default App
