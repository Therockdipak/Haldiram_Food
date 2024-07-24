// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract HaldiramFood is ReentrancyGuard {
    address payable public owner;
    bool private paused;

    struct Food {
        string name;
        uint256 quantity;
        uint256 price;
        uint256 expirationDate; // Expiration date as a UNIX timestamp
        bool isAdded;
        bool condition;
        bool sold;
    }

    mapping(uint256 => Food) public foods;

    event FoodAdded(uint256 tokenNumber, string name, uint256 quantity, uint256 price, uint256 expirationDate);
    event FoodChecked(uint256 tokenNumber, string name, uint256 quantity, bool condition);
    event FoodBought(uint256 tokenNumber, uint256 quantity, uint256 totalPrice);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event FoodPriceUpdated(uint256 tokenNumber, uint256 newPrice);
    event FoodRestocked(uint256 tokenNumber, uint256 quantity);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
        paused = false;
    }

    // Function to transfer ownership of the contract to a new owner
    function transferOwnership(address payable newOwner) external onlyOwner nonReentrant {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // Function to pause the contract
    function pause() external onlyOwner whenNotPaused nonReentrant {
        paused = true;
        emit Paused(msg.sender);
    }

    // Function to unpause the contract
    function unpause() external onlyOwner whenPaused nonReentrant {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // Function to add a new food item with a specific token number
    function addFood(uint256 tokenNo, string memory name, uint256 quantity, uint256 price, uint256 expirationDate) external onlyOwner whenNotPaused {
        require(!foods[tokenNo].isAdded, "Product already added");
        foods[tokenNo] = Food(name, quantity, price, expirationDate, true, true, false);
        emit FoodAdded(tokenNo, name, quantity, price, expirationDate);
    }

    // Function to check the condition of a food item
    function checkFood(uint256 tokenNo) external onlyOwner whenNotPaused returns (bool) {
        require(foods[tokenNo].isAdded, "Product not added");
        bool condition = foods[tokenNo].condition;

        // Check if the food has expired
        if (block.timestamp > foods[tokenNo].expirationDate) {
            condition = false;
            foods[tokenNo].isAdded = false;
        }

        emit FoodChecked(tokenNo, foods[tokenNo].name, foods[tokenNo].quantity, condition);
        return condition;
    }

    // Function to update the price of a food item
    function updatePrice(uint256 tokenNo, uint256 newPrice) external onlyOwner whenNotPaused nonReentrant {
        require(foods[tokenNo].isAdded, "Product not added");
        foods[tokenNo].price = newPrice;
        emit FoodPriceUpdated(tokenNo, newPrice);
    }

    // Function to restock a food item
    function restockFood(uint256 tokenNo, uint256 quantity) external onlyOwner whenNotPaused {
        require(foods[tokenNo].isAdded, "Product not added");
        foods[tokenNo].quantity += quantity;
        foods[tokenNo].sold = false;
        emit FoodRestocked(tokenNo, quantity);
    }

    // Function to buy a food item
    function buyFood(uint256 tokenNo, uint256 quantity_) external payable whenNotPaused nonReentrant {
        Food storage food = foods[tokenNo];
        require(food.isAdded, "Food not added");
        require(food.condition, "Food is not in a sellable condition");
        require(food.quantity >= quantity_, "Unavailable quantity, please try with less amount");

        uint256 totalPrice = quantity_ * food.price;
        require(msg.value >= totalPrice, "Insufficient balance");
        owner.transfer(totalPrice);

        food.quantity -= quantity_;
        if (food.quantity == 0) {
            food.sold = true;
        }

        emit FoodBought(tokenNo, quantity_, totalPrice);

        // Refund any excess amount sent
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }
}
