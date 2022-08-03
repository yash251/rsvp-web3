// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Web3RSVP {
    struct CreateEvent {
        bytes32 eventId;
        string eventDataCID; // reference to an IPFS hash for storing details like the event’s name and event description
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
    }

    mapping(bytes32 => CreateEvent) public idToEvent;

    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
        // generating an eventID
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );

        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;

        // this creates a new CreateEvent struct and adds it to the idToEvent mapping
        idToEvent[eventId] = CreateEvent(
            eventId,
            eventDataCID,
            msg.sender,
            eventTimestamp,
            deposit,
            maxCapacity,
            confirmedRSVPs,
            claimedRSVPs,
            false // because at the time of eventCreation, there have been no payouts to the RSVPers (there are none yet) or the event owner yet
        );
    }

    function createNewRSVP(bytes32 eventId) external payable {
        // look up event from our mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        // transfer deposit to our contract / require that they send in enough ETH to cover the deposit requirement of this specific event
        require(msg.value == myEvent.deposit, "Not enough deposit");

        // require that the event hasn't already happened (<eventTimestamp)
        require(block.timestamp <= myEvent.eventTimestamp, "Already happened");

        // make sure event is under max capacity
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "This event has reached maximum capacity"
        );

        // require that msg.sender isn't already in myEvent.confirmedRSVPs AKA hasn't already RSVP'd
        for (uint8 index = 0; index < myEvent.confirmedRSVPs.length; index++) {
            require(
                myEvent.confirmedRSVPs[index] != msg.sender,
                "Already confirmed"
            );
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));
    }
}
