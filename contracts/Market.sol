pragma solidity ^0.4.4;

contract Market{

    struct Item{
        //Owner of the item
        address owner;
        // Description of the item
        string description;
        //Price of the item
        uint price;
    }

    // Item added in the system
    event Created (
        uint itemId
    );
    // Item deleted in the system
    event Deleted (
        uint itemId
    );
    //Item bought
    event Bought(
        uint itemId
    );
    //Item sold
    event Sold(
        uint itemId,
        uint price
    );
    //Item listed
    event Listed(
        uint itemId,
        uint price
         
    );
    //Item unlisted
    event Unlisted(
        uint itemId
    );


    //Address of the owner of an item
    address ownerAddress;
    // Listings of items
    mapping(uint => uint) public listing;
    //Array of the items
    Item[] public items;
    // Balances for items sold
    mapping(address => uint) public balances;

    // Check that the sender is the owner of the item
    modifier onlyOwner(uint _itemId) {
        require (items[_itemId].owner == msg.sender);
        _;
    }

    // Initiate the contract
    function Market() {
        ownerAddress = msg.sender;
    }

    // List an item
    function list(uint _itemId, uint price) onlyOwner(_itemId) {
        listing[_itemId] = price;
        Listed(_itemId, price);

    }

    // Un-list an item
    function unlist(uint _itemId) onlyOwner(_itemId) {
        require(listing[_itemId] != 0);
        listing[_itemId] = 0;
        Unlisted(_itemId);
    }

    function buy(uint _itemId) onlyOwner(_itemId) {
        require(listing[_itemId] > 0);
        require(items[_itemId].price >0);
        require(msg.value >= items[_itemId].price);
        require(items[_itemId].owner > 0);
        
        listing[_itemId] = 0;
        balances[items[_itemId].owner] += msg.value;
        items[_itemId].owner = msg.sender;
        Sold(_itemId,msg.value);

    }

    // Add a new item to the system
    function addItem(address initialOwner, string description, uint price ) onlyOwner(itemId) returns (uint itemId) {

        require(initialOwner > 0);

        items.push(Item(initialOwner, description, price));
        itemId = items.length - 1;

        Created(itemId);
    }

    function changePrice(uint _itemId, uint _price) onlyOwner(_itemId) {
        require(listing[_itemId] > 0);
        require(_price > 0);

        listing[_itemId] = _price;

    }

}