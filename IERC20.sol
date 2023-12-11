// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// implement the IERC20 interface
interface IERC20 {
    function totalSupply() external view returns(uint);
    // * total supply tracks the total amount of token being mint and bunt

    function balanceOf(address account) external view returns(uint);
    // * balanceOf returns the ERC token that the account has

    function transfer(address recipient, uint amount) external returns(bool);
    // * transfer allows the holder of ERC20 token to transfer his token to recipient

    function approve(address spender, uint amount) external returns(bool);
    // * approve allows an owner to approve someone else to transfer his token on his behalf

    function allowance(address owner, address spender) external view returns(uint);
    // * if an owner wants to authorize someone else to transfer his token on his bahalf, he needs to specify who can

    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
    // * after someone is allowed to transfer an owner's token, he uses this function 

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

}


contract ERC20 is IERC20 {
    // create a state variable to track the total money
    uint public totalSupply;
    // create a mapping to represent how much each user has tokens
    mapping(address => uint) public balanceOf;
    // create a nested mapping to track the authorization of an owner and the allowance monery for each sender
    mapping(address => mapping(address => uint)) public allowance;
    
    // define the token info
    string public name = "FA591token";
    string public symbol = "FAT";
    uint8 public decimals = 18;
    // * 10^18 is one of this token

    function transfer(address recipient, uint amount) external returns(bool){
        // update the balanceOf for both the owner and recipient
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);

        return true;
        // * if the function is executed correctly without error, it will return true
    }


    function approve(address spender, uint amount) external returns(bool){
        // define owner allow which sender how much money they can spend
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }


    function transferFrom(address sender, address recipient, uint amount) external returns(bool){
        // update the amount of sender and recipient
        balanceOf[sender] -= amount;
        // * note that in this case the sender is in fact the one who approve the spender
        balanceOf[recipient] += amount; 

        // update the usage of allowance
        allowance[sender][msg.sender] -= amount;
        // * note that the msg.sender in this case is in fact the one who is allowed to use token from sender/
        //   the one who is authorized call this function

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
        // * because we are creating new tokens rather than transfering some from another address \
        //   we put address(0) in from parameter
    }
    // * we allow owner to mint any amount of token

    
    function bunt(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);

    }

    

}

