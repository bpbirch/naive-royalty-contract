pragma solidity ^0.8.0;

/*
@dev the reason we use internal is that should not be called from the outside,
because the account sending and paying for a transaction may not be 
the actual sender in the case of meta-transactions

*/
abstract contract Context {
    function msgSender() internal view returns(address) {
        return msg.sender;
    }
}