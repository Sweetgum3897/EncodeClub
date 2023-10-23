// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract GasContract {
    uint256 immutable totalSupply; // cannot be updated 
  //  uint256 constant tradeFlag = 1;
 //   uint256 constant basicFlag = 0;
 //   uint256 constant dividendFlag = 1;
    uint256 public paymentCounter = 0;
    mapping(address => uint256) public balances;
    //uint256 public tradePercent = 12;
    address public contractOwner;
   // uint256 public tradeMode = 0;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    PaymentType constant defaultPayment = PaymentType.Unknown;

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }


    uint256 wasLastOdd = 1;
    //mapping(address => uint256) public isOddWhitelistUser;
    
    struct ImportantStruct {
        uint256 amount;
        bool paymentStatus;
    }
    mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
   /* event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );*/
    event WhiteListTransfer(address indexed);

    modifier onlyAdminOrOwner() {
         address senderOfTx = msg.sender;
        if (checkForAdmin(senderOfTx)) {
            _;
        } else if (senderOfTx == contractOwner) {
            _;
        } else {
            revert(
                "onlyAdminOrOwner"
            );
        }
    }

modifier checkIfWhiteListed(address sender) {
    address senderOfTx = msg.sender;
    uint256 usersTier = whitelist[senderOfTx];

    require(
        senderOfTx == sender && usersTier > 0 && usersTier <= 3,
        "Transaction failed checks"
    );

    _;
}

    constructor(address[] memory _admins, uint256 _totalSupply) {
        address _contractOwner = msg.sender;
        contractOwner = _contractOwner;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == _contractOwner) {
                    balances[_contractOwner] = _totalSupply;
                } 
                if (_admins[ii] == _contractOwner) {
                    emit supplyChanged(_admins[ii], _totalSupply);
                }
            }
        }
    }

 function addToWhitelist(address _userAddrs, uint256 _tier)
        public
        onlyAdminOrOwner
    {   
    require(
            _tier < 255,
            "tier should not be greater than 255"
        );

        if (_tier > 3) {
            whitelist[_userAddrs] = 3;
        } else {
            whitelist[_userAddrs] = _tier;
        }
        uint256 wasLastAddedOdd = wasLastOdd;
        if (wasLastAddedOdd == 1) {
            wasLastOdd = 0;
        } else {
            wasLastOdd = 1;
        } 
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function balanceOf(address _user) external view returns (uint256 balance_) {
        uint256 balance = balances[_user];
        return balance;
    }

       function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public {
        address senderOfTx = msg.sender;
        
        require(
            senderOfTx != address(0),
            "User must have a valid non zero address"
        );
        require(
            balances[senderOfTx] >= _amount,
            "Sender has insufficient Balance"
        );
        require(
            bytes(_name).length < 9,
            "recipient name has max length of 8 characters"
        );
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        Payment memory payment;
        payment.admin = address(0);
        payment.adminUpdated = false;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name;
        payment.paymentID = ++paymentCounter;
        payments[senderOfTx].push(payment);
        /*bool[] memory status = new bool[](tradePercent);
        for (uint256 i = 0; i < tradePercent; i++) {
            status[i] = true;
        }
        return (status[0] == true);*/
    }
  
  function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed(msg.sender){
        address senderOfTx = msg.sender;
        whiteListStruct[senderOfTx] = ImportantStruct(_amount, true);

           require(
            senderOfTx != address(0),
            "User must have a valid non zero address"
        );
        
        require(
            balances[senderOfTx] >= _amount,
            "Sender has insufficient Balance"
        );
        require(
            _amount > 3,
            "amount to send has to be more than 3"
        );
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        balances[senderOfTx] += whitelist[senderOfTx];
        balances[_recipient] -= whitelist[senderOfTx];
        
        emit WhiteListTransfer(_recipient);
    }


    function checkForAdmin(address _user) internal view returns (bool admin_) {
        bool admin = false;
        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                admin = true;
            }
        }
        return admin;
    }

 /*   function getTradingMode() internal pure returns (bool mode_) {
        bool mode = false;
        if (tradeFlag == 1 || dividendFlag == 1) {
            mode = true;
        } else {
            mode = false;
        }
        return mode;
    }

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) public onlyAdminOrOwner {
        require(
            _ID > 0,
            "ID must be greater than 0"
        );
        require(
            _amount > 0,
            "Amount must be greater than 0"
        );
        require(
            _user != address(0),
            "Administrator must have a valid non zero address"
        );

        address senderOfTx = msg.sender;

        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            if (payments[_user][ii].paymentID == _ID) {
                payments[_user][ii].adminUpdated = true;
                payments[_user][ii].admin = _user;
                payments[_user][ii].paymentType = _type;
                payments[_user][ii].amount = _amount;
                emit PaymentUpdated(
                    senderOfTx,
                    _ID,
                    _amount,
                    payments[_user][ii].recipientName
                );
            }
        }
    }*/

    function getPaymentStatus(address sender) external view returns (bool, uint256) {        
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }


    fallback() external payable {
         payable(msg.sender).transfer(msg.value);
    }
}