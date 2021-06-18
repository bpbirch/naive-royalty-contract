pragma solidity ^0.8.0;

import "./Context.sol";

contract Owners is Context {
    mapping (address => bool) contractOwners;

    constructor() {
        setFirstOwner(msgSender());
    }

    event ownerAdded(address addr);

    event ownerRemoved(address addr);

    modifier onlyOwners() {
        require(contractOwners[msgSender()] == true);
        _;
    }

    function addOwners(address newAddress) public virtual onlyOwners {
        contractOwners[newAddress] = true;
        emit ownerAdded(newAddress);
    }

    function setFirstOwner(address firstAddress) private {
        contractOwners[firstAddress] = true;
    }

    function removeSelfFromOwners() public onlyOwners {
        contractOwners[msgSender()] = false;
        emit ownerRemoved(msgSender());
    }
    

}