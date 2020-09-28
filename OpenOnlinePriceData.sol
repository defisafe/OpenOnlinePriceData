pragma solidity >=0.6.2;

import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";


contract OpenOnlinePriceData {

    using SafeMath for uint256;
    IUniswapV2Factory public v2Factory;
    address public ethTokenAddress;
    address public usdtTokenAddress;
    address private owner;
    uint256 public slipRange;

    constructor(address _ethAddress,address _usdtAddress, address _v2Factory, uint256 _slipRange) public {
        require(_ethAddress != address(0),"_ethAddress error .");
        require(_usdtAddress != address(0),"_usdtAddress error .");
        require(_v2Factory != address(0),"_v2Factory error .");

        ethTokenAddress = _ethAddress;
        usdtTokenAddress = _usdtAddress;
        v2Factory = IUniswapV2Factory(_v2Factory);
        slipRange = _slipRange;

        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    function setEthTokenAddress(address _ethAddress) public onlyOwner {
        require(_ethAddress != address(0),"_ethAddress error .");
        ethTokenAddress = _ethAddress;
    }
    

    function setv2Factory(address _v2Factory)public onlyOwner {
        require(_v2Factory != address(0),"_v2Factory error .");
        v2Factory = IUniswapV2Factory(_v2Factory);
    }
    
    function setUsdtTokenAddress(address _usdtAddress)public onlyOwner {
        require(_usdtAddress != address(0),"_usdtAddress error .");
       usdtTokenAddress = _usdtAddress;
    }
    
    function setSlipRange(uint256 _slipRange)public onlyOwner {
       slipRange = _slipRange;
    }


    function getPriceTokenToUsdt(address srcTokenAddress)public view returns(uint256 isValid,uint256 tokenToUsdtPrice){
        require(srcTokenAddress != address(0),"srcTokenAddress error .");
        require(srcTokenAddress != usdtTokenAddress,"srcTokenAddress != usdtTokenAddress,error .");
        if(srcTokenAddress == ethTokenAddress){
            //eth-usdt
            return(10,getReservesTokenAToTokenB(ethTokenAddress,usdtTokenAddress));
        }else{
            //eth-token
            uint256 tokenToEth = getReservesTokenAToTokenB(srcTokenAddress,ethTokenAddress);
            uint256 ethToUsdt = getReservesTokenAToTokenB(ethTokenAddress,usdtTokenAddress);
            uint256 tokenToUsdt_A = mulDiv(tokenToEth,ethToUsdt,1e18);
            //token-usdt
            uint256 tokenToUsdt_B = getReservesTokenAToTokenB(srcTokenAddress,usdtTokenAddress);
            if(tokenToUsdt_A > tokenToUsdt_B){
                uint256 actualSlip = mulDiv(tokenToUsdt_B,slipRange,100);
                (isValid,tokenToUsdtPrice) = tokenToUsdt_B.add(actualSlip) > tokenToUsdt_A ? (10,tokenToUsdt_A) : (0,0);
            }else if(tokenToUsdt_A < tokenToUsdt_B){
                uint256 actualSlip = mulDiv(tokenToUsdt_A,slipRange,100);
                (isValid,tokenToUsdtPrice) = tokenToUsdt_A.add(actualSlip) > tokenToUsdt_B ? (10,tokenToUsdt_B) : (0,0);
            }else{
                return (10,tokenToUsdt_B);
            }
        }
    }

    function getReservesTokenAToTokenB(address tokenA,address tokenB)public view returns(uint256 tokenATotokenB) {
        address pairAddress = v2Factory.getPair(tokenA,tokenB);
        require(pairAddress != address(0),"tokenA-tokenB pairAddress error .");
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint reserves0, uint reserves1,) = pair.getReserves();
        (uint reserveA,uint reserveB) = tokenA == pair.token0() ? (reserves0, reserves1) : (reserves1, reserves0);
        tokenATotokenB = mulDiv(reserveB,1e18,reserveA);
    }

    function mulDiv (uint256 _x, uint256 _y, uint256 _z) public pure returns (uint256) {
        uint256 temp = _x.mul(_y);
        return temp.div(_z);
    }
}