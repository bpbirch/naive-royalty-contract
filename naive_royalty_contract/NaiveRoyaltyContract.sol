pragma solidity ^0.5.13;

contract NaiveRoyaltyContract {  
    address public contractOwner; 
    uint256 public tokenCount;
    uint256 public percentageFeeForTransaction;
    uint256 public mintingFee;
    
    modifier 
    onlyOwner() {
        require(msg.sender == contractOwner, "Only conrtract owner can call this function");
        _;
    }
    constructor() 
    public 
    {
        tokenCount = 1;
        contractOwner = msg.sender;
        mintingFee = 1 ether;
        percentageFeeForTransaction = 5;
    }
    
    function setPercentageFeeForTransaction (uint256 percentage)
    public
    onlyOwner
    {
        percentageFeeForTransaction = percentage;
    }
    
    function setMintingFee (uint256 fee) 
    public 
    onlyOwner
    {
        mintingFee = fee*10**18 / 100;
    }
    
    struct User {
        uint256[] deposits;
        uint256[] withdrawals;
        uint256 userBalance;
        mapping (uint256 => bool) ownedTokens; // if tokenID 233 owned by user, then ownedTokens[233] = 1 else 0
    }

    struct TokenInfo 
    {
        address tokenOwner;
        uint256 tokenPrice;
        address tokenCreator;
        bool tokenForSale;
        uint256 tokenRoyaltyPercentage;
    }
    
    mapping (address => User) public userInfo;
    mapping (uint256 => TokenInfo) public tokenMapping;
    
    function getUserDeposits(address addr) public view returns(uint256[] memory) {
        return userInfo[addr].deposits;
    }
    
    function getUserWithdrawals(address addr) public view returns(uint256[] memory) {
        return userInfo[addr].withdrawals;
    }
    
    
    function getUserBalance(address addr) public view returns(uint256) {
        return userInfo[addr].userBalance;
    }
    
    function mintToken(uint256 price, uint256 royaltyPercentage)
    public
    {
        require(userInfo[msg.sender].userBalance >= mintingFee);
        address creator = msg.sender;
        uint256 ethPrice = price*10**18;
        // create a token object:
        TokenInfo memory tokenInfo;
        tokenInfo.tokenCreator = creator;
        tokenInfo.tokenPrice = ethPrice;
        tokenInfo.tokenOwner = creator;
        tokenInfo.tokenForSale = true;
        tokenInfo.tokenRoyaltyPercentage = royaltyPercentage;
        // transfer necessary funds 
        userInfo[contractOwner].userBalance += mintingFee; // the contract owner keeps the fee
        userInfo[msg.sender].userBalance -= mintingFee;
        // userInfo[msg.sender].ownedTokens[tokenCount] = 1; // establish ownership by minter
        tokenMapping[tokenCount] = tokenInfo;
        tokenCount += 1;

    }
    
    function buyToken(uint tokenID) 
    public
    {
        require(tokenMapping[tokenID].tokenForSale == true);
        uint256 transactionFee = percentageFeeForTransaction * tokenMapping[tokenID].tokenPrice/100;
        uint256 totalOwed = transactionFee + tokenMapping[tokenID].tokenPrice;
        require(userInfo[msg.sender].userBalance >= totalOwed);
        address currentOwner = tokenMapping[tokenID].tokenOwner;
        uint256 royalty = tokenMapping[tokenID].tokenRoyaltyPercentage * tokenMapping[tokenID].tokenPrice / 100;
        userInfo[msg.sender].userBalance -= totalOwed;
        userInfo[tokenMapping[tokenID].tokenOwner].userBalance += tokenMapping[tokenID].tokenPrice - royalty;
        userInfo[contractOwner].userBalance += transactionFee; // owner keeps transaction fee
        userInfo[tokenMapping[tokenID].tokenCreator].userBalance += royalty;
        
        // the next two lines transfer ownership in users' ownedTokens arrays
        userInfo[msg.sender].ownedTokens[tokenID] = true;
        userInfo[currentOwner].ownedTokens[tokenID] = false;
        // the next two lines transfer ownership in our tokenMapping map
        tokenMapping[tokenID].tokenOwner = msg.sender;
        tokenMapping[tokenID].tokenForSale = false; // take token off the market once it's purchased
    }
    
    function reduceTokenRoyaltyPercentage(uint256 tokenID, uint256 newRoyaltyPercentage) 
    public 
    {
        // reduce token royalty - only creator can call this function
        require(tokenMapping[tokenID].tokenCreator == msg.sender, "only token creator can change token royalty");
        require(newRoyaltyPercentage >= 0 && newRoyaltyPercentage <= 100 && newRoyaltyPercentage <= tokenMapping[tokenID].tokenRoyaltyPercentage);
        tokenMapping[tokenID].tokenRoyaltyPercentage = newRoyaltyPercentage;
    }
    
    function sellToken(uint256 tokenID, uint256 newPrice)
    public 
    {
        require(tokenMapping[tokenID].tokenOwner == msg.sender, "only token owner can sell token");
        require(newPrice > 0, "new price must be greater than 0");
        tokenMapping[tokenID].tokenPrice = newPrice*10**18;
        tokenMapping[tokenID].tokenForSale = true;
    }
    
    function depositFunds()
    public 
    payable 
    {
        uint256 amount = msg.value;
        userInfo[msg.sender].userBalance += amount;
        userInfo[msg.sender].deposits.push(amount);
    }
    
    function withDrawFunds(uint amount) 
    public 
    payable 
    {
        uint256 ethAmount = amount*10**18;
        require(userInfo[msg.sender].userBalance >= ethAmount);
        address payable to = msg.sender; 
        to.transfer(ethAmount);
        userInfo[msg.sender].userBalance -= ethAmount;
        userInfo[msg.sender].withdrawals.push(ethAmount);
    }
    
    function withdrawAllFunds()
    public 
    payable 
    {
        address payable to = msg.sender;
        to.transfer(userInfo[msg.sender].userBalance);
        userInfo[msg.sender].userBalance = 0;
    }
    
    
    
    
}