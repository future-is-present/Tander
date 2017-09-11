pragma solidity 0.4.16;

/// @title Multi-signature token wallet - Allows multiple parties to approve tokens transfer
/// @author manolodewiner  

contract MultiSigTokenWallet {
    /// @dev No fallback function to prevent ether deposit


    event Confirmation(address source, uint actionId);
    event Revocation(address source, uint actionId);
    event TransactionCreation(uint actionId);
    event TransactionDeletion(uint actionID);
    event TokenTransfer(uint actionId);
    event TokenTransferFailure(uint actionId);
    event OwnerAddition(address owner);
    event OwnerRemoval(address owner);
    event QuorumChange(uint quorum);

    enum TransactionChoices { AddOwner, WithdrawOwner, ChangeQuorum, DeleteTransaction}
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public quorum;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        TransactionChoices transactionType;
        bool executed;
        bool deleted;
    }

    modifier ownerDeclared(address owner) {
        require (isOwner[owner]);
        _;
    }

    modifier transactionSubmitted(uint transactionId) {
        require (   transactions[transactionId].destination != 0
                 || transactions[transactionId].value != 0);
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require (confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require (!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require (!transactions[transactionId].executed);
        _;
    }

    modifier notDeleted(uint transactionId) {
        require (!transactions[transactionId].deleted);
        _;
    }

    modifier validQuorum(uint ownerCount, uint _quorum) {
        require (_quorum <= ownerCount && _quorum > 0);
        _;
    }

    modifier validTransaction(address  destination, uint value, TransactionChoices transactionType) {
        require (  (transactionType == TransactionChoices.AddOwner      && destination != 0 && value == 0)
                || (transactionType == TransactionChoices.ChangeQuorum  && destination == 0 && value > 0)
                || (transactionType == TransactionChoices.DeleteTransaction  && destination == 0 && value > 0)
                || (transactionType == TransactionChoices.WithdrawOwner && destination != 0 && value == 0));
        _;
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _quorum Number of required confirmations.
    function MultiSigTokenWallet(address[] _owners, uint _quorum)
        public
        validQuorum(_owners.length, _quorum)
    {
        for (uint i=0; i<_owners.length; i++) {
            require (!isOwner[_owners[i]] && _owners[i] != 0);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        quorum = _quorum;
    }

    /// @dev Allows to add a new owner. 
    /// @param owner Address of new owner.
    function addOwner(address owner)
        private
    {
        require(!isOwner[owner]);
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

    /// @dev Allows to withdraw an owner. 
    /// @param owner Address of owner.
    function withdrawOwner(address owner)
        private
    {
        require (isOwner[owner]);
        require (owners.length - 1 >= quorum);
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        OwnerRemoval(owner);
    }

    /// @dev Allows to change the number of required confirmations.
    /// @param _quorum Number of required confirmations.
    function changeQuorum(uint _quorum)
        private
    {
        require (_quorum > 0 && _quorum <= owners.length);
        quorum = _quorum;
        QuorumChange(_quorum);
    }

    /// @dev Adds a new transaction to the transaction list, if transaction does not exist yet.
    /// @param destination address to send token or too add or withadraw as owner.
    /// @param value number of tokens (useful only for token transfer).
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, TransactionChoices transactionType)
        private
        returns (uint)
    {
        transactionCount += 1;
        uint transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            transactionType: transactionType,
            executed: false,
            deleted: false
        });
        TransactionCreation(transactionId);
        return transactionId;
    }

    /// @dev Allows to delete a previous transaction not executed
    /// @param _transactionId Number of required confirmations.
    function deleteTransaction(uint _transactionId)
        private
        notExecuted(_transactionId)
    {
        transactions[_transactionId].deleted = true;
        TransactionDeletion(_transactionId);
    }

   

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Number of token / new quorum to reach.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, TransactionChoices transactionType)
        public
        ownerDeclared(msg.sender)
        validTransaction(destination, value, transactionType)
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, transactionType);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        ownerDeclared(msg.sender)
        transactionSubmitted(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        Confirmation(msg.sender, transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerDeclared(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        ownerDeclared(msg.sender)
        transactionSubmitted(transactionId)
        notExecuted(transactionId)
        notDeleted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction memory transaction = transactions[transactionId];
            transaction.executed = true;
            if (transaction.transactionType == TransactionChoices.AddOwner)
                addOwner(transaction.destination);
            else if (transaction.transactionType == TransactionChoices.ChangeQuorum)
                changeQuorum(transaction.value);
            else if (transaction.transactionType == TransactionChoices.DeleteTransaction)
                deleteTransaction(transaction.value);
            else if (transaction.transactionType == TransactionChoices.WithdrawOwner)
                withdrawOwner(transaction.destination);
            else
                revert();
        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == quorum)
                return true;
        }
        return false;
    }

    /// @dev Returns number of confirmations of an transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed, bool exceptDeleted)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   ((pending && !transactions[i].executed)
                    || (executed && transactions[i].executed))
                && (!exceptDeleted || !transactions[i].deleted))
                count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @param exceptDeleted Exclude deleted transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(bool pending, bool executed, bool exceptDeleted)
        public
        constant
        returns (uint[] memory)
    {
        uint[] memory transactionIds;
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (((pending && !transactions[i].executed)
                 || (executed && transactions[i].executed))
                && (!exceptDeleted || !transactions[i].deleted))
            {
                transactionIds[count] = i;
                count += 1;
            }
            
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
