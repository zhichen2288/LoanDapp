// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "./IERC20.sol";
import "./BondingCurve.sol";


contract LoanFactory {
    // set start and end to tract time period
    uint startAt;
    uint endAt;
    uint public IR;

    // make a pointer to IERC20 contract
    IERC20 public immutable token;
    BondingCurve public immutable curve;

    constructor(address _token, address _curve){
        token = IERC20(_token);
        curve = BondingCurve(_curve);
    }


    struct Application {
        address borrower;
        uint target;
        uint raisedFund;
        uint startAt;
        uint endAt;
        bool claimed; 
    }

    // store the applications in a mapping
    mapping(uint => Application) public applicationsMP;
    uint public applicationID;

    // keep track of fund of each lender
    mapping(uint => mapping(address => uint)) public lenderFundMP;

    event LoanLog(
        uint applicationID,
        address indexed borrower,
        uint target
    );

    event CancelLoanLog(
        uint applicationID
    );

    event fundLog(
        uint indexed lenderID,
        address indexed lender,
        uint amount
    );

    event defundLog(
        uint indexed lenderID,
        address indexed lender,
        uint amount
    );

    event claimLog(
        uint applicationID
    );

    event refundLog(
        uint indexed lenderID,
        address indexed lender,
        uint amount
    );


    // make an application to get specific amount of loan
    function getLoan(uint _target) external {

            startAt = block.timestamp + 1 minutes;
            endAt = startAt + 1 minutes;
         
            applicationsMP[applicationID] = Application({
                borrower: msg.sender,
                target: _target,
                raisedFund: 0,
                startAt: startAt,
                endAt: endAt,
                claimed: false
            });
            applicationID += 1;

            emit LoanLog(applicationID, msg.sender, _target);
    }


    function getInterestRate(uint _target, uint _downpayment) external returns(uint){
        uint IDRatio = (_downpayment/_target)*100;
        IR = curve.getInteresRate(IDRatio);

        return IR;
    }


    // undo the application if the loan did not start yet
    function cancel(uint _applicationID) external {
        Application memory oneApplication = applicationsMP[_applicationID];
        require(msg.sender == oneApplication.borrower, "this operation is only for borrower.");
        require(block.timestamp < oneApplication.startAt, "this application is already started.");

        delete applicationsMP[_applicationID];

    }


    // allow lenders to put the money in after the application start 
    function fund(uint _lenderID, uint _amount) external {
        Application storage oneApplication = applicationsMP[_lenderID];
        
        // make sure the funding process is in the valid period
        require(block.timestamp >= oneApplication.startAt, "this application is not started yet.");
        require(block.timestamp <= oneApplication.endAt, "this application is closed already.");

        // update application info
        oneApplication.raisedFund += _amount;

        // track lender's fund
        lenderFundMP[_lenderID][msg.sender] += _amount;

        // transfer token from account to this contract
        token.transferFrom(msg.sender, address(this), _amount);

        emit fundLog(_lenderID, msg.sender, _amount);
    }


    // allow lenders to withdraw the money if they change their mind when the application is still going
    function defund(uint _lenderID, uint _amount) external {
        Application storage oneApplication = applicationsMP[_lenderID];
        require(block.timestamp <= oneApplication.endAt, "this application is closed already.");

        oneApplication.raisedFund -= _amount;
        lenderFundMP[_lenderID][msg.sender] -= _amount;

        token.transfer(msg.sender, _amount);

        emit defundLog(_lenderID, msg.sender, _amount);

    }


    // if the fund is larger than target, the borrower can claim the money
    function claim(uint _applicationID) external {
        Application storage oneApplication = applicationsMP[_applicationID];
        require(msg.sender == oneApplication.borrower, "This opeation is only for borrower.");
        require(block.timestamp > oneApplication.endAt, "This application is not closed yet.");
        require(oneApplication.raisedFund >= oneApplication.target, "the raised fund did not reach to target.");
        // make sure the token can only be claimed once
        require(!oneApplication.claimed, "This application is already clamied");

        oneApplication.claimed = true;
        token.transfer(msg.sender, oneApplication.raisedFund);

        emit claimLog(_applicationID);
    }


    // if the fund is smaller than target, meaning that the application is unsuccessful \
    // the lender can ask for the refund
    function refund(uint _lenderID) external {
        Application storage oneApplication = applicationsMP[_lenderID];
        require(block.timestamp > oneApplication.endAt, "This application is not closed yet.");
        require(oneApplication.raisedFund < oneApplication.target, "the raised fund did not reach to target.");

        uint onelenderfund = lenderFundMP[_lenderID][msg.sender];
        lenderFundMP[_lenderID][msg.sender] = 0;
        token.transfer(msg.sender, onelenderfund);

        emit refundLog(_lenderID, msg.sender, onelenderfund);
        
    }



}