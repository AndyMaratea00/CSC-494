// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ecommerce {
    address public owner;
    uint256 public revenue;
    uint256 public transactionCounter;

    struct Product {
        uint256 price;
        uint256 stock;
        int noItem;
        int unitCost;
    }

    struct Transaction {
        address customer;
        uint256 productId;
        uint256 quantity;
        uint256 unitCost;
    }

    mapping(uint256 => Product) public products;
    mapping(uint256 => Transaction) public transactions;

    string public ownerName;
    int public totalProducts;

    constructor(uint256 laptopPrice, uint256 laptopStock, uint256 watchPrice, uint256 watchStock, uint256 tvPrice, uint256 tvStock) {
        owner = msg.sender;
        revenue = 0;
        transactionCounter = 1;

        products[1] = Product(laptopPrice, laptopStock, 0, 0);
        products[2] = Product(watchPrice, watchStock, 0, 0);
        products[3] = Product(tvPrice, tvStock, 0, 0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function generateTransactionId() internal returns (uint256) {
        return transactionCounter++;
    }

    function purchase(uint256 productId, uint256 quantity) external payable {
        require(productId >= 1 && productId <= 3, "Invalid product ID");
        require(quantity > 0, "Quantity must be greater than zero");
        require(products[productId].stock >= quantity, "Insufficient stock");
        require(msg.value == products[productId].price * quantity, "Incorrect payment amount");

        uint256 transactionId = generateTransactionId();
        revenue += msg.value;
        products[productId].stock -= quantity;
        transactions[transactionId] = Transaction(msg.sender, productId, quantity, products[productId].price);
    }

    function changePrice(uint256 productId, int256 value) external onlyOwner {
        require(productId >= 1 && productId <= 3, "Invalid product ID");
        require(int256(products[productId].price) + value >= 0, "Price cannot be negative");
        products[productId].price = uint256(int256(products[productId].price) + value);
    }

    function addItem(uint256 productId, uint256 quantity) external onlyOwner {
        require(productId >= 1 && productId <= 3, "Invalid product ID");
        require(quantity > 0, "Quantity must be greater than zero");
        products[productId].stock += quantity;
    }

    function mostPopularProduct() external view returns (uint256) {
        uint256 mostPopularProductId;
        uint256 maxTotalPurchase = 0;

        for (uint256 i = 1; i <= 3; i++) {
            if (products[i].stock > maxTotalPurchase) {
                maxTotalPurchase = products[i].stock;
                mostPopularProductId = i;
            }
        }

        return mostPopularProductId;
    }

    function returnItems(uint256 transactionId) external onlyOwner {
        require(transactionId >= 1, "Invalid transaction ID");
        Transaction storage transaction = transactions[transactionId];
        require(transaction.customer != address(0), "Transaction does not exist");
        uint256 refundAmount = transaction.quantity * transaction.unitCost;
        require(address(this).balance >= refundAmount, "Insufficient balance for refund");
        payable(transaction.customer).transfer(refundAmount);
        delete transactions[transactionId];
    }

    function getStock(uint256 productId) external view returns (uint256) {
        require(productId >= 1 && productId <= 3, "Invalid product ID");
        return products[productId].stock;
    }
}
