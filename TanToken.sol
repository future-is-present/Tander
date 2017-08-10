pragma solidity ^0.4.0;

contract owned {

    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}
/*******************************************************************************
 * ERC Token Standard #20 Interface
 * https://github.com/ethereum/EIPs/issues/20
 *******************************************************************************/
contract ERC20Interface {
    // Get the total token supply
    function totalSupply() constant returns (uint256 totalsSupply);

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns (uint256 balance);

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) returns (bool success);

    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality.
    function approve(address _spender, uint256 _value) returns (bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract TanToken is ERC20Interface, owned {

    uint256 public totalSupply; // Total supply of the tokens
    uint256 supply = 0;
    address public owner; // Owner of this contract

    /* Balance for each account */
    mapping(address => uint256) balances;
    /* True if account holder approves the transfer of an amount to another account */
    mapping (address => mapping (address => uint256)) allowed;

    /* Initialize the supply */
    function TanToken (uint256 _initialSupply) {
        supply = _initialSupply;
    }

    function totalSupply() constant returns (uint256 totalsSupply){
        return supply;
    }


    /* Transfer an amount from the owner's account to an indicated account */
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
        if (balances[_from] >= _amount
        && allowed[_from][msg.sender] >= _amount
        && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balances[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }

}