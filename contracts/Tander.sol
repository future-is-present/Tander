pragma solidity ^0.4.11;

contract Tander {


    struct Item{
        uint price;
        address owner;
        uint state; //0=nothing  1=selling 2=sold
    }

    //All items
    Item[] items;

    //The item selected
    Item ChosenItem;


    mapping(address => uint256) balances;
    items;



    function offerItem(uint i){

        ChosenItem

    }

    /**
        *@notice returns the address of the selected owner
        *@return address of the owner
        */
    function getChosenOwner() external constant returns (address) {
        return ChosenItem.owner;
    }


    function resolveOffer(address _buyer, uint256 _amount) returns (bool success){

        if(_amount<items) throw;
        items[].state=3;



    }

}