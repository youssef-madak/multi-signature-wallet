// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.17;

 contract MultisignatureWallet{


    event Deposite(
        address indexed sender,
        uint256 amount,
        uint256 balance
    );
    event SubmitTransaction(
        address owner,
        uint256 transactionID,
        address transactionTo,
        uint256 value,
        bytes data
    );
    event ConfirmationTransaction(
        address owner,
        uint256 indexed transactionID
    );
    event RevokeConfirmation(
        address owner,
        uint256 indexed transactionID
    );
    event ExecuteConfirmation(
        address owner,
        uint256 indexed transactionID
    );

    //array contain all owners address
    address[] owners;

    //using mapp to check existance of address in array
    mapping(address => bool) public isOwner;

    //number of confirmations from owners to execute transaction 
    uint256 public numConfirmationRequired;

    //create object called transaction  with all this info
    struct Transaction{
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }


    mapping (uint256 => mapping(address => bool)) public inConfirmed;

    //create array of transaction using struct
    Transaction[]    transactions;

    // create restriction 
    modifier onlyOwner(){
        require(isOwner[msg.sender], "Only Owners allowed");
        _;
    }

    //restriction by cjheck existance of transaction
    modifier transactionExiste(uint256 _transactionId){
        require(_transactionId < transactions.length, "transaction does not exist");
        _;

    }
    // check if the transaction has been already executed
    modifier notExecuted(uint256 _transactionId){
        require(
            !transactions[_transactionId].executed, "transaction already executed" // transactionid refers to index of transaction in transaction array
            
        );
        _;
    }
    //check if transaction is not confirmed
    modifier notConfirmed(uint256 _transactionId){
        require(!inConfirmed[_transactionId][msg.sender], 'transaction is already confirmed');
        _;
    }

    //Create constructor
    constructor(address[] memory _owners, uint256 _numberOfConfirmationRequired){
        require(_owners.length > 0, "oiwners required");
        require(_numberOfConfirmationRequired > 0 && _numberOfConfirmationRequired <= _owners.length,
        "Invalid number of required confirmations");//confirmation must be less than owners number

        for(uint256 i; i <_owners.length; i++){
            address owner = _owners[i];

            require(owner != address(0), "Invalid Owner" );//address(0) is address for burn tokens
            require(!isOwner[owner], "owner not unique"); //must be not be duplicated

            isOwner[owner] = true;
            owners.push(owner);

            numConfirmationRequired = _numberOfConfirmationRequired;
        }}

    receive() external payable{
        emit Deposite(msg.sender, msg.value, address(this).balance);
    }
     // create functon to submit transaction
    function submitTransaction(address _to, uint256 _value, bytes memory _data )public  onlyOwner{
        //transaction id = last number of transactions in array
        uint256 transactionId = transactions.length;

        //push transaction object with initialized values in transaction array
        transactions.push(
            Transaction({
                to : _to,
                value : _value,
                data : _data,
                executed : false, //whait for confirmation and execution
                numConfirmations : 0 //whait for confirmation and execution
            })
        );
        emit SubmitTransaction(msg.sender, transactionId, _to, _value, _data);
    }

    //after submiting we have transaction info in array
    function confirmationTransaction(uint256 _txIndex ) 
        public 
        onlyOwner
        transactionExiste (_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
        {
            Transaction storage transaction = transactions[_txIndex];
            transaction.numConfirmations +=1;
            inConfirmed[_txIndex][msg.sender] = true;

            emit ConfirmationTransaction(msg.sender, _txIndex);


    }

    // create function to execute transaction after confirmation

    function executeTransaction(uint256 _txIndex)
        public 
        onlyOwner
        transactionExiste(_txIndex)
        notExecuted(_txIndex)
        {
            Transaction storage transaction = transactions[_txIndex];
            require(transaction.numConfirmations >= numConfirmationRequired, "cannot execute the transaction");
            transaction.executed = true;
            (bool success,)=  transaction.to.call{value: transaction.value}(
                transaction.data
            );
            require(success, "transaction failed");
            emit ExecuteConfirmation(msg.sender, _txIndex);
    }

    //create remove confirmations (retreat) from owners

    function removeConfirmation(uint256 _txIndex) 
    public
    onlyOwner
    transactionExiste(_txIndex)
    notExecuted(_txIndex)
    {
            Transaction storage transaction = transactions [_txIndex];
            require(inConfirmed[_txIndex][msg.sender], "transaction not confirmed"); //,ust this address already confirm the transaction
            transaction.numConfirmations -= 1; //decrement num of confirmations
            inConfirmed[_txIndex][msg.sender] = false; // for that address (address of owner) the confirmation false
            emit RevokeConfirmation(msg.sender, _txIndex); //revoke the confirmation

    }

    //get all owners in this contract 
    function getOwners()public view returns(address[] memory){
        return owners;
    }

    //get all transaction count function
    function getTransactionCount() public view returns(uint256){
        return transactions.length;
    }

    //get transaction by id 
    function getTransaction(uint256 _txIndex) public view returns(
        address to,
        uint256 value,
        bytes memory data,
        bool executed,
        uint256 numConfirmations
        
    ){
        Transaction storage transaction  = transactions[_txIndex];
        return(
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
    



}
 