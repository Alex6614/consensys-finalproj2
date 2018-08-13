pragma solidity ^0.4.23;
// Use https://github.com/Arachnid/solidity-stringutils for string splitting
// Note that I technically don't need this.. if I turn Resource.parts into an array

// Change this later to point to downloaded local file
import "./strings.sol";


// TODO: 
// 0) Create a function that resets EVERYTHING
//  i) Every update to the contract state should have a corresponding event tied to it
//  ii) Add openzeppellin split amount integration (do by saving payees in an array first)
// iii) Add ipfs
    // iii-a) https://github.com/ipfs/js-ipfs/tree/master/examples, https://github.com/ipfs/js-ipfs/tree/master/examples/ipfs-101 
// iv) Add check that part (make this a modifier) and subparts (check in-function) exist, for notify

// Stretch Goals

// Split up payments for multiple people if more than one part specified.



// In progress: Switch whitelist users to whitelist user. Ensure that the tests are also changed

contract SupplyChainEP {
    using strings for *;
    
    /* set owner */
    address owner;

    /* getting information from resource name */
    mapping (string => Resource) resourceInfo;

    struct Resource {
        address source;
        string name; // Note that IRL, these could be EPCs
        string parts; // space separated names of parts
        mapping (address => bool) whitelistedUsers;
    }

    mapping (address => string) resources;

    mapping (address => Request[]) requests;

    struct Request {
        bool directRequest; // If it's just a warning, then this is false
        string resourceName;
        address requester;
        uint reward;
        string ipfsHash;
    }

    /* Events */
    event requestSent(string resourceName, address _address);
    event warningSent(uint numberOfWarnings);
    event userWhitelisted(string part, address whitelisteduser);
    event resourceAdded(string part, string subparts);
    event debugString(string debug);
    event debugString2(string debug);
    event debugInt(uint debug);

    event gothere();
    event debugBool(bool boolean);

    /* Modifiers */
    modifier verifyCaller (address _address) {require (msg.sender == _address); _;}
    modifier isSource (string part) {require (resourceInfo[part].source == msg.sender); _;}
    modifier isOwner () {require(msg.sender == owner); _;}
    modifier notEmpty (string _string) {bytes memory stringTest = bytes(_string); require (stringTest.length != 0); _;}

    constructor() public {
        owner = msg.sender;
    }

    // When notifying people, you also send warnings to one level further down
    function notify(string parts, string _ipfsHash)
        payable
        public
    {   
        Resource storage r = resourceInfo[parts];
        emit gothere();
        emit debugBool(r.whitelistedUsers[msg.sender]);

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
                    requester: r.source, // We give the name of the manufacturer that is one up, so as to protect name of user of part higher up
                    reward: 0,
                    ipfsHash: ""
                }));
            }
            emit warningSent(subparts.length);
        }
    }

    // Add a resource to the blockchain with your address
    // part names should be space separated
    function addResource(string _resourceName, string _partNames)
        public
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

    function myResources()
        public
        view
        returns(string)
    {
        return resources[msg.sender];
    }
    
    // This is for resource manufacturers to whitelist companies in order to allow them to send
    // errors. Set state to 'true' if you want to whitelist users, and 'false' if you want
    // to remove them from the whitelist
    function whitelistUser(string part, address _whitelistedUser, bool state)
        public
        isSource(part)
    {
        // Save the reference to the mapping inside the resource struct
        resourceInfo[part].whitelistedUsers[_whitelistedUser] = state;
        emit userWhitelisted(part, _whitelistedUser);
    }


    // function whitelistUser(string part, address _whitelistedUsers, bool state)
    //     public
    //     isSource(part)
    // {
    //     // Save the reference to the mapping inside the resource struct
    //     mapping (address => bool) map = resourceInfo[part].whitelistedUsers;

    //     // Iterate through the given whitelisted users and save the info in the resource
    //     for (uint i = 0; i < _whitelistedUsers.length; i++) {
    //         map[_whitelistedUsers[i]] = state;
    //     }
    // }



    // This is for manufacturers to receive their requests and receive their payments
    // This would eventually delete all the requests by the end of the transaction
    function getRequests()
        public
        returns (bool[], address[], uint)
    {
        Request[] storage r = requests[msg.sender];
        bool[] memory isWarning = new bool[](r.length);
        address[] memory notifiers = new address[](r.length);
        uint payment = 0;
        
        for(uint i = 0; i < r.length; i++) {
            isWarning[i] = r[i].directRequest;
            notifiers[i] = r[i].requester;
            payment = payment + r[i].reward;
        }
        msg.sender.transfer(payment);
        delete requests[msg.sender];
        return (isWarning, notifiers, payment);
    }

    function seeRequests()
        view
        public
        returns (bool[], address[], uint, string)
    {
        Request[] storage r = requests[msg.sender];
        bool[] memory isWarning = new bool[](r.length);
        address[] memory notifiers = new address[](r.length);
        uint payment = 0;

        string ipfs_hash;

        for(uint i = 0; i < r.length; i++) {
            isWarning[i] = r[i].directRequest;
            notifiers[i] = r[i].requester;
            payment = payment + r[i].reward;
            ipfs_hash = ipfs_hash.toSlice().concat(r.ipfsHash.toSlice());
            ipfs_hash = ipfs_hash.toSlice().concat(",".toSlice());
        }
        return (isWarning, notifiers, payment, ipfs_hash);
    }

    // For Debugging
    function getSubparts(string part)
        public
        returns (string)
    {
        return resourceInfo[part].parts;
    }

    // For Debugging. To be tested on a part that has two subparts
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