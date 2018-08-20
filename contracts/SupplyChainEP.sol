pragma solidity ^0.4.23;

// Use https://github.com/Arachnid/solidity-stringutils for string splitting
import "./strings.sol";

/** @title Supply Chain Error Propagation Contract */
contract SupplyChainEP {
    using strings for *;

    // Keeps track of status of circuit breaker
    bool private stopped = false;
    
    // Keeps track of owner
    address owner;

    // Input string to get information about resource
    mapping (string => Resource) resourceInfo;

    // Struct containing information on resource
    struct Resource {
        address source;
        string name;
        string parts; // Space separated components of parts
        mapping (address => bool) whitelistedUsers;
    }

    // Grabs the name of the resources based on address
    mapping (address => string) resources;

    // Provides array of requests that a user has
    mapping (address => Request[]) requests;

    // Struct containing information on request
    struct Request {
        bool directRequest; // Errors are true, warnings are false.
        string resourceName;
        address requester;
        uint reward;
        string ipfsHash;    // Address of IPFS file
    }

    // Events
    event requestSent(string resourceName, address _address);
    event warningSent(uint numberOfWarnings);
    event userWhitelisted(string part, address whitelisteduser);
    event resourceAdded(string part, string subparts);
    event debugString(string debug);
    event debugString2(string debug);
    event debugInt(uint debug);
    event stoppedChange(bool status);
    event gothere();
    event debugBool(bool boolean);

    // Modifiers
    modifier verifyCaller (address _address) {require (msg.sender == _address); _;}
    modifier isSource (string part) {require (resourceInfo[part].source == msg.sender); _;}
    modifier isOwner () {require(msg.sender == owner); _;}
    modifier notEmpty (string _string) {bytes memory stringTest = bytes(_string); require (stringTest.length != 0); _;}
    modifier stopInEmergency {require(!stopped); _;}

    /**
        @dev Initializes the contract
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
        @dev Toggles circuit breaker state, if you are admin. Emits "stoppedChange" event.
     */
    function toggleContractActive() isOwner public {
        stopped = !stopped;
        emit stoppedChange(stopped);
    }

    /**
        @dev Sends notifications and warnings for a given part, so long as sender is whitelisted for the part. Also pays 1 ether to the owner.
        @param parts Name of the part whose owner is to be notified
        @param _ipfsHash Address of the file in IPFS
     */
    function notify(string parts, string _ipfsHash)
        payable
        stopInEmergency
        public
    {   
        Resource storage r = resourceInfo[parts];
        emit gothere();
        emit debugBool(r.whitelistedUsers[msg.sender]);

        // Push error to owner of the part
        if(r.whitelistedUsers[msg.sender]) {
            requests[r.source].push(Request({
                directRequest: true,
                resourceName: r.name,
                requester: msg.sender,
                reward: msg.value,
                ipfsHash: _ipfsHash
            }));
            emit requestSent(r.name, r.source);

            // Push warnings to each of the subparts
            var s = r.parts.toSlice();
            var delim = " ".toSlice();
            var subparts = new string[](s.count(delim) + 1);
            for(uint j = 0; j < subparts.length; j++) {
                subparts[j] = s.split(delim).toString();
            }
            for (uint i = 0; i < subparts.length; i++) {
                Resource storage r2 = resourceInfo[subparts[i]];
                requests[r2.source].push(Request({
                    directRequest: false,
                    resourceName: r2.name,
                    requester: r.source,
                    reward: 0,
                    ipfsHash: ""
                }));
            }
            emit warningSent(subparts.length);
        }
    }

    /**
        @dev Adds a resource to the blockchain under the sender's address
        @param _resourceName The name of the new resource
        @param _partNames The name of the new resource's subparts, space separated
     */
    function addResource(string _resourceName, string _partNames)
        public
        stopInEmergency
        notEmpty(_resourceName)
    {
        // First see if resource is empty
        if (resourceInfo[_resourceName].source == 0) {
            resourceInfo[_resourceName] = Resource({source: msg.sender, name: _resourceName, parts: _partNames});
            
            // Then add to owner's string of resources
            var s = " ".toSlice().concat(_resourceName.toSlice());
            resources[msg.sender] = resources[msg.sender].toSlice().concat(s.toSlice());

            // Emit event
            emit resourceAdded(_resourceName, _partNames);
        }
    }

    /**
        @dev Provides a list of one's own resources
        @return s A string containing space separated names of resources that the sender owns
     */
    function myResources()
        public
        view
        returns(string)
    {
        return resources[msg.sender];
    }
    
    /**
        @dev Whitelist another user for a part to allow them to send notifications to you.
        @param part Name of the part to allow other user to send errors for
        @param _whitelistedUser Address of other user
        @param state True to whitelist, false to remove them from the resource's whitelist
     */
    function whitelistUser(string part, address _whitelistedUser, bool state)
        public
        stopInEmergency
        isSource(part)
    {
        // Save the reference to the mapping inside the resource struct
        resourceInfo[part].whitelistedUsers[_whitelistedUser] = state;
        emit userWhitelisted(part, _whitelistedUser);
    }

    /**
        @dev Return all error notifications and warnings that belongs to the sender. Erases error notifications and warnings for that sender within the blockchain.
        @return bool[] List of boolean values that corresponds to whether notification at a certain index is an error notification or a warning
        @return address[] List of addresses that have sent the sender a notification
        @return uint Amount of ether sent by the requests
        @return string The ipfs addresses combined into one string, comma separated
     */
    function getRequests()
        public
        stopInEmergency
        returns (bool[], address[], uint, string)
    {
        Request[] storage r = requests[msg.sender];
        bool[] memory isWarning = new bool[](r.length);
        address[] memory notifiers = new address[](r.length);
        uint payment = 0;

        string memory ipfs_hash;
        
        for(uint i = 0; i < r.length; i++) {
            isWarning[i] = r[i].directRequest;
            notifiers[i] = r[i].requester;
            payment = payment + r[i].reward;
            ipfs_hash = ipfs_hash.toSlice().concat(r[i].ipfsHash.toSlice());
            ipfs_hash = ipfs_hash.toSlice().concat(",".toSlice());
        }
        
        msg.sender.transfer(payment);
        delete requests[msg.sender];
        return (isWarning, notifiers, payment, ipfs_hash);
    }

    /**
        @dev Checks the current status of the circuit breaker
        @return bool True if circuit breaker is on, false otherwise
     */
    function checkEmergencyStop()
        public
        view
        returns (bool)
    {
        return stopped;
    }

    /**
        @dev Gets the subparts of a given resource
        @param part The name of the part, whose subparts you are looking for
        @return string A strng containing space separated names of subparts
     */
    function getSubparts(string part)
        public
        returns (string)
    {
        return resourceInfo[part].parts;
    }

    /**
        @dev A debugging function to check if the string library is working correcntly. Grabs the first two subparts of a part
        @param part The part whose first two subparts are to be checked
     */
    function splitSubparts(string part)
        public
    {
        var s = resourceInfo[part].parts.toSlice();
        var delim = " ".toSlice();
        emit debugInt(s.count(delim) + 1);
        var subparts = new string[](s.count(delim) + 1);
        for(uint i = 0; i < subparts.length; i++) {
            subparts[i] = s.split(delim).toString();
        }
        emit debugString(subparts[0]);
        emit debugString2(subparts[1]);
    }
}