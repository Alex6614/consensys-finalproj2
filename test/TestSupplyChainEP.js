var SupplyChainEP = artifacts.require('SupplyChainEP')
var Strings = artifacts.require("strings")

contract('SupplyChainEP', function(accounts) {
    const dell = accounts[0]
    const intel = accounts[1]
    const siltronic = accounts[2]
    const codelco = accounts[3]
    const testaccount = accounts[4]

    const price = web3.toWei(1, "ether")
    const sampleipfs = "thisisanipfshash"

    describe('general-tests', function() {
        it("should return the same subparts that was entered when resource was created", async() => {
            const scep = await SupplyChainEP.deployed()
            const strings = await Strings.deployed()
    
            const sample_part_one = "part1"
            const sample_part_one_subparts = "subpart1 subpart2"
    
            await scep.addResource(sample_part_one, sample_part_one_subparts)
    
            const result = await scep.getSubparts.call(sample_part_one)
    
            assert.equal(result, sample_part_one_subparts, 'the inputted subparts does not match the output subparts')
    
        })
    
        it("should be able to split subparts using the string library", async() => {
            const scep = await SupplyChainEP.deployed();
            const strings = await Strings.deployed()
    
            const sample_part_one = "part1"
            const sample_part_one_subparts = "subpart1 subpart2"
    
            await scep.addResource(sample_part_one, sample_part_one_subparts)
    
            var eventEmitted1 = false
    
            var eventarg1
            var event1 = scep.debugString()
            await event1.watch((err, res) => {
                eventEmitted1 = true
                eventarg1 = res.args.debug
            })
    
            var eventEmitted2 = false
    
            var eventarg2
            var event2 = scep.debugString2()
            await event2.watch((err, res) => {
                eventEmitted2 = true
                eventarg2 = res.args.debug.toString(5)
            })
    
    
            var eventEmitted3 = false
    
            var eventarg3
            var event3 = scep.debugInt()
            await event3.watch((err, res) => {
                eventEmitted3 = true
                eventarg3 = res.args.debug
            })
    
    
            await scep.splitSubparts(sample_part_one)
    
            assert.equal(eventEmitted1, true, 'the program was not able to emit an event for first debugString')
            assert.equal(eventarg1, "subpart1", 'the program was not able to get the first subpart')
            assert.equal(eventEmitted2, true, 'the program was not able to emit an event for debugString2')
            assert.equal(eventarg2, "subpart2", 'the program was not able to get the second subpart')
            assert.equal(eventEmitted3, true, 'the program was not able to emit an event for debugInt')
            assert.equal(eventarg3, 2, 'the program was not able to get the number of subparts')
        })
    
        it("should be able to add a resource", async() => {
            const scep = await SupplyChainEP.deployed();
            const strings = await Strings.deployed();
            const testpart1 = "testpart"
            const testsubparts1="testsubpart1 testsubpart2"
    
            var resourceAddedEmitted = false
            var resourceAddedArgPart
            var resourceAddedArgSubpart
            var resourcesAddedEvent = scep.resourceAdded()
            await resourcesAddedEvent.watch((err, res) => {
                resourceAddedEmitted = true
                resourceAddedArgPart = res.args.part
                resourceAddedArgSubpart = res.args.subparts
            })
    
            await scep.addResource(testpart1, testsubparts1, {from: testaccount})
    
            assert.equal(resourceAddedEmitted, true, 'the program was not able to emit an event for adding a resource')
            assert.equal(resourceAddedArgPart, testpart1, 'the program was not able to emit an event with the right part')
            assert.equal(resourceAddedArgSubpart, testsubparts1, 'the program was not able to emit an event with the right subparts')
    
        })
    
        it("should be able to whitelist users", async() => {    
            const scep = await SupplyChainEP.deployed();
            const strings = await Strings.deployed();

            const testpart1 = "testpart1"
            const testsubpart1 = ""
            await scep.addResource(testpart1, testsubpart1, {from: testaccount})

            var resourceAddedEmitted = false
            var resourceAddedArgPart
            var resourceAddedArgSubpart
            var resourcesAddedEvent = scep.resourceAdded()
            await resourcesAddedEvent.watch((err, res) => {
                resourceAddedEmitted = true
                resourceAddedArgPart = res.args.part
                resourceAddedArgSubpart = res.args.subparts
            })
    
            // Set up listener for whitelisting
            var whitelistEventEmitted = false
            var whitelistArgPart
            var whitelistUserpart
            var whitelistEvent = scep.userWhitelisted()
            await whitelistEvent.watch((err, res) => {
                whitelistEventEmitted = true
                whitelistArgPart = res.args.part
                whitelistUserpart = res.args.whitelisteduser
            })
            
            await scep.whitelistUser(testpart1, dell, true, {from: testaccount})

            assert.equal(whitelistEventEmitted, true, 'the program was not able to emit an event for whitelisting users')
            assert.equal(whitelistArgPart, testpart1, 'the program was not able to emit an event for the part related to the whitelist')
            assert.equal(whitelistUserpart, dell, 'the program was not able to emit an event for the user to be whitelisted')

        })
        it("should be able to toggle the circuit breaker", async() => {
            const scep = await SupplyChainEP.deployed();
            const strings = await Strings.deployed()
    
            var circuitBreakerEventEmitted = false
    
            var circuitBreakerStatus
            var circuitBreakerEvent = scep.stoppedChange()
            await circuitBreakerEvent.watch((err, res) => {
                circuitBreakerEventEmitted = true
                circuitBreakerStatus = res.args.status
            })

            await scep.toggleContractActive()
    
            assert.equal(circuitBreakerEventEmitted, true, 'the program was not able to emit an event for toggling the circuit break')
            assert.equal(circuitBreakerStatus, true, 'the program was not able to toggle the circuit breaker')
        })
    })
})