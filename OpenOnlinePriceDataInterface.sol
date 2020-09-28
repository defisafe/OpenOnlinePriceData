pragma solidity >=0.6.2;

interface OpenOnlinePriceData {
    function getPriceTokenToUsdt(address srcTokenAddress)external view returns(uint256 isValid,uint256 tokenToUsdtPrice);
}
