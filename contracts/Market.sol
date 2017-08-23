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
    event Created (
        uint itemId
    );
    //Item bought
    event Bought(
        uint itemId
    );
    //Item sold
    event Sold(
        uint itemId
    );
    //Item listed
    event Listed(
        uint itemId
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
    function list(uint _itemId, uint price) onlyOwner(_recordId) {
        listing[_itemId] = price;
        Listed(_itemId, price);

    }

    // Un-list an item
    function unlist(uint _itemId) onlyOwner(_recordId) {
        require(listing[_itemId] != 0);
        listing[_itemId] = 0;
        Unlisted(_itemId);
    }

    function buy(uint _itemId) onlyOwner {
        if(listing[_recordId] <= 0
            || items[_itemId].price <=0
            || msg.balance < items[_itemId].price
            || items[_itemId].owner == 0
        )
        throw;
        listing[_itemId] = 0;
        balances[ items[_itemId].owner ] += msg.value;
        items[_itemId].owner = msg.sender;
        Sold(_recordId,msg.value);

    }

    // Add a new item to the system
    function addItem(address initialOwner, string description ) onlyOwner returns (uint itemId) {

        if(initialOwner == 0
            || description == 0)
        throw;

        items.push(Record(initialOwner, description, "", imgUrls, warehouse, now, storagePaidThru, storageFee, lateFee,  RecordState.inWarehouse));
        itemId = items.length - 1;

        Created(recordId);
    }

    function changePrice(uint _itemId, uint _price) onlyOwner {
        if(listing[_itemId] == 0
        || _price == 0)
        throw;

        listing[_itemId] = _price;

    }

}