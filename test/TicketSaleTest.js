const TicketSale = artifacts.require("TicketSale");
const { expect } = require("chai");

contract("TicketSale", (accounts) => {
  let ticketSaleInstance;
  const owner = accounts[0];
  const alice = accounts[1];
  const bob = accounts[2];

  before(async () => {
    ticketSaleInstance = await TicketSale.new(3, web3.utils.toWei("10000", "wei"));
  });

  it("should allow a user to buy a ticket", async () => {
    const ticketId = 1;
    await ticketSaleInstance.buyTicket(ticketId, { from: alice, value: web3.utils.toWei("10000", "wei") });
    const aliceTicketId = await ticketSaleInstance.getTicketOf(alice);
    expect(aliceTicketId.toNumber()).to.equal(ticketId);
  });

  it("should allow a user to offer a swap", async () => {
    const ticketId = 2;
    await ticketSaleInstance.buyTicket(ticketId, { from: bob, value: web3.utils.toWei("10000", "wei") });
    await ticketSaleInstance.offerSwap(alice, { from: bob });
    const swapOffer = await ticketSaleInstance.swapOffers(bob);
    expect(swapOffer).to.equal(alice);
  });

  it("should allow a user to accept a swap", async () => {
    const aliceTicketIdBefore = await ticketSaleInstance.getTicketOf(alice);
    const bobTicketIdBefore = await ticketSaleInstance.getTicketOf(bob);

    await ticketSaleInstance.acceptSwap(bob, { from: alice });

    const aliceTicketIdAfter = await ticketSaleInstance.getTicketOf(alice);
    const bobTicketIdAfter = await ticketSaleInstance.getTicketOf(bob);

    expect(aliceTicketIdBefore.toNumber()).to.equal(1); // Alice's initial ticket
    expect(bobTicketIdBefore.toNumber()).to.equal(2); // Bob's initial ticket
    expect(aliceTicketIdAfter.toNumber()).to.equal(2); // Alice's ticket after the swap
    expect(bobTicketIdAfter.toNumber()).to.equal(1); // Bob's ticket after the swap
});


it("should allow a user to return a ticket and emit a refund event", async () => {
  const ticketId = 1;
  await ticketSaleInstance.buyTicket(ticketId, { from: alice, value: web3.utils.toWei("10000", "wei") });

  const initialBalance = web3.utils.toBN(await web3.eth.getBalance(alice));
  const ticketPrice = await ticketSaleInstance.ticketPrice();
  const serviceFeePercentage = await ticketSaleInstance.serviceFeePercentage();

  // Check if you own the ticket
  const aliceTicketId = await ticketSaleInstance.getTicketOf(alice);
  expect(aliceTicketId.toNumber()).to.equal(ticketId);

  const receipt = await ticketSaleInstance.returnTicket(ticketId, { from: alice });
  const gasCost = web3.utils.toBN(receipt.receipt.gasUsed).mul(web3.utils.toBN(web3.utils.toWei('1', 'gwei')));

  const finalBalance = web3.utils.toBN(await web3.eth.getBalance(alice));
  const expectedRefund = web3.utils.toBN(ticketPrice).mul(web3.utils.toBN(100 - serviceFeePercentage)).div(web3.utils.toBN(100));

  expect(finalBalance.toString()).to.equal(initialBalance.add(expectedRefund).sub(gasCost).toString());

  // Check if the TicketReturned event was emitted
  const ticketReturnedEvent = receipt.events.TicketReturned;
  expect(ticketReturnedEvent).to.not.be.undefined;
  expect(ticketReturnedEvent.returnValues.owner).to.equal(alice);
  expect(parseInt(ticketReturnedEvent.returnValues.ticketId)).to.equal(ticketId);
  expect(web3.utils.toBN(ticketReturnedEvent.returnValues.refundAmount).toString()).to.equal(expectedRefund.toString());
});

});