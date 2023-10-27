pragma solidity ^0.8.17;

contract TicketSale {
    address public manager;
    uint public ticketPrice;
    uint public numTickets;
    uint public serviceFeePercentage = 10;
    
    mapping(address => uint) public addressToTicketId;
    mapping(uint => address) public ticketIdToOwner;
    mapping(address => address) public swapOffers;
    
    constructor(uint _numTickets, uint _price) {
        manager = msg.sender;
        numTickets = _numTickets;
        ticketPrice = _price;
    }

    function buyTicket(uint ticketId) public payable {
    require(ticketId >= 1 && ticketId <= numTickets, "Invalid ticket id");
    require(msg.value == ticketPrice, "Incorrect ether amount sent");
    require(addressToTicketId[msg.sender] == 0, "You already have a ticket");
    require(ticketIdToOwner[ticketId] == address(0), "Ticket already sold");

    addressToTicketId[msg.sender] = ticketId;
    ticketIdToOwner[ticketId] = msg.sender;
    }


    function getTicketOf(address person) public view returns (uint) {
        return addressToTicketId[person];
    }

    function offerSwap(address partner) public {
        require(addressToTicketId[msg.sender] > 0, "You don't have a ticket to swap");
        require(addressToTicketId[partner] > 0, "Partner doesn't have a ticket to swap");
        swapOffers[msg.sender] = partner;
    }

    function acceptSwap(address partner) public {
    require(swapOffers[partner] == msg.sender, "No swap offer from partner");
    uint myTicketId = addressToTicketId[msg.sender];
    uint partnerTicketId = addressToTicketId[partner];
    addressToTicketId[msg.sender] = partnerTicketId;
    addressToTicketId[partner] = myTicketId;
    delete swapOffers[partner];
    }


    function returnTicket(uint ticketId) public {
        require(msg.sender == ticketIdToOwner[ticketId], "You don't own this ticket");
        
        uint refundAmount = (ticketPrice * (100 - serviceFeePercentage)) / 100;
        payable(msg.sender).transfer(refundAmount);
        ticketIdToOwner[ticketId] = address(0);
        addressToTicketId[msg.sender] = 0;
    }
}