//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

//to run demo
//compile
//deploy the compute Address
//run get bytecode(owner address of computeAddress, and any number)
//get bytecode and copy it
//call getAddress, (bytecode, pass in salt(any number))
//the result should be the address of the contract that will be deployed
//run deploy to compare (copy bytecode from getbytecode, enter the same salt from previously)
//check logs from emitted event

contract computeAddress{
    event Deployed(address addr, uint256 salt);

    //gets bytecode of the contract to be deployed
    function getByteCode(address _owner, uint _foo) public pure returns (bytes memory){
        bytes memory byteCode = type(TestContract).creationCode;
        return abi.encodePacked(byteCode, abi.encode(_owner, _foo));
    }

    //compute the address of the contract to be deployed
    //keccak256(0xff + sender address + salt(random number of choice) + keccak256(creation code))
    //take the last 20 bytes^
    function getAddress(bytes memory byteCode, uint _salt) public view returns (address){
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),//will be the adress of the computeAddress contract
                _salt,
                keccak256(byteCode)
            )
        );

        return address(uint160(uint256(hash)));
    }

    //deploys contract using create2
    function deploy(bytes memory byteCode, uint _salt) public payable {
        address addr;

        //how to use create2
        //create2(v, p, n, s)
        //v - amount of eth to send
        //p - pointer to start of code in memory
        //n - size of code
        //s - salt
        assembly {
            addr := create2(
                callvalue(),//wei sent with current call
                //actual code starts after skipping the first 32 byts
                add(byteCode, 0x20),
                mload(byteCode), //load the size of code contained in the first 32 bytes
                _salt //random chosen number
            )
            if iszero(extcodesize(addr)){
                revert(0, 0)
            }
        }
        emit Deployed(addr, _salt);
    }

}

contract TestContract {
    address public owner;
    uint public foo;

    constructor(address _owner, uint _foo) payable {
        owner = _owner;
        foo = _foo;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
