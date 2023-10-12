const Ecommerce = artifacts.require("Ecommerce");

async function runTests() {
  const accounts = await web3.eth.getAccounts();

  const ecommerceInstance = await Ecommerce.new(
    100, 10, 50, 20, 500, 5
  );

  const owner = await ecommerceInstance.owner();
  assert.equal(owner, accounts[0], "Test 1: Owner is not set correctly");

  const productId = 1;
  const newValue = 150;
  await ecommerceInstance.changePrice(productId, newValue, { from: accounts[0] });
  const product = await ecommerceInstance.products(productId);
  assert.equal(product.price.toNumber(), newValue, "Test 2: Price not changed");

  const quantity = 20;
  await ecommerceInstance.addItem(productId, quantity, { from: accounts[0] });
  const stock = await ecommerceInstance.getStock(productId);
  assert.equal(stock.toNumber(), 30, "Test 3: Stock not added");

  const nonOwner = accounts[1];
  const nonOwnerTry = async () => {
    await ecommerceInstance.changePrice(productId, 200, { from: nonOwner });
  };

  try {
    await nonOwnerTry();
    assert.fail("Test 4: Non-owner was able to change price");
  } catch (error) {
    assert.include(error.message, "Only the owner can call this function", "Test 4: Non-owner was able to change price");
  }
  
  console.log("All tests passed successfully.");
}

runTests().catch(error => {
  console.error("Error in tests:", error);
  process.exit(1);
});
