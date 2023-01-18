// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
 import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20{
  address public tokenAddress;

    constructor(address _tokenAddress)ERC20("dyx" , "dfy"){
      require(_tokenAddress != address(0),"invalid address");
      tokenAddress=_tokenAddress;
    }
    //流动性的增加与移除
    //增加流动性
  function addLiquidity(uint256 _amount)public payable returns(uint256){
    //当前池子中不具有流动性
    if (getReserve()==0) {
      //将提供流动性的用户的钱转入合约中
      IERC20 token= IERC20(tokenAddress);
      token.transferFrom(msg.sender, address(this), _amount);
      //流动性计算
       uint256 liquidity = address(this).balance;
       //奖励
      _mint(msg.sender, liquidity);
      return liquidity;
    }else{
      //当前池子中的
      uint256 ethReserve = address(this).balance - msg.value;//计算value进入之前池子中的eth数量
      uint256 tokenReserve = getReserve();//获取当前池子中的token数量
      uint256 tokenAmount  = (msg.value * tokenReserve)/ethReserve;
      require(tokenAmount<=_amount,"invalid amount");
      IERC20 token = IERC20(tokenAddress);
      token.transferFrom(msg.sender, address(this), tokenAmount);
      //流动性计算
      uint256 liquidity = (totalSupply() * msg.value)/ethReserve;
      _mint(msg.sender, liquidity);
      return liquidity;
    } 
    
  }
//移除流动性
function removeLiquidity(uint256 _amount)public  returns(uint256,uint256){
    require(_amount>0,"invalid");
    uint256 ethAmount =address(this).balance *  _amount / totalSupply();
    uint256 tokenAmount =getReserve() *  _amount / totalSupply();

    _burn(msg.sender, _amount);
    payable(msg.sender).transfer(ethAmount);
    IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    return(ethAmount,tokenAmount);
  }

  function getReserve() public view returns (uint256){
    return IERC20(tokenAddress).balanceOf(address(this));
  }
  //对手续费的计算以及计算汇率
  function getAmount(uint256 inputAmount,uint256 inputReserve, uint256 outputReserve)private pure returns(uint256){
    require(inputReserve > 0&&outputReserve > 0,"invalid reserves");

    uint256 inputAmountWithFee = (inputAmount*3)/1000;
    uint256 inputAmountWithoutFee = inputAmount-inputAmountWithFee;
    uint256 numerator = inputAmountWithoutFee*outputReserve;
    uint256 denominator = inputAmountWithoutFee + inputReserve  ;
    return numerator/denominator;
  }
  //交易功能
  //获取当前eth能换多少token
    function getTokenAmount(uint256 _ethSold)public view returns(uint256){
    require(_ethSold > 0,"invalid");
    uint256 tokenReserve = getReserve();
    return getAmount(_ethSold, address(this).balance, tokenReserve);
  }
  //获取当前token能换多少eth
    function getEtherAmount(uint256 _tokenSold)public view returns(uint256){
    require(_tokenSold > 0,"invalid");
    uint256 tokenReserve = getReserve();
    return getAmount(_tokenSold, tokenReserve, address(this).balance);
  }
  //实现eth换取token
  function ethToTokenSwap(uint256 _minTokens)public payable{
    uint256 tokenReserve = getReserve();
    uint256 tokenBought = getAmount(msg.value, address(this).balance-msg.value, tokenReserve);
    
    require(tokenBought>=_minTokens,"insuffcient output");
    IERC20(tokenAddress).transfer(msg.sender, tokenBought);
  }
//实现token换取eth
  function TokenToethSwap(uint256 _tokenSold,uint256 _minEth)public {
    uint256 tokenReserve = getReserve();
    uint256 ethBought = getAmount(_tokenSold, tokenReserve,address(this).balance);
    
    require(ethBought>=_minEth,"insuffcient output");
    IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);
    payable(msg.sender).transfer(ethBought);
  }
  //滑点百分比计算
  function CaculateEthSlippage(uint256 _ethSold)public view returns(uint256){
    return _ethSold/(getReserve()+_ethSold);
  }

  function CaculateTokenSlippage(uint _tokenSold)public view returns(uint256){
    return _tokenSold/(address(this).balance+_tokenSold);
  }
}