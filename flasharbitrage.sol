// SPDX-License-Identifier: MIT pragma solidity ^0.6.6; pragma experimental ABIEncoderV2;

import "@aave/protocol-v2/contracts/flashloan/base/FlashLoanReceiverBase.sol"; import "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol"; import "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol"; import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; import "./IKyberNetworkProxy.sol"; import "./IUniswap.sol";

contract FlashArbitrage is FlashLoanReceiverBase { address public owner; address kyberAddress = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755; address uniswapAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

constructor(ILendingPoolAddressesProvider _provider) FlashLoanReceiverBase(_provider) public {
    owner = msg.sender;
}

modifier onlyOwner() {
    require(msg.sender == owner, "only owner");
    _;
}

function executeArbitrage(address asset, uint256 amount, address token1, address token2, bool kyberFirst) external onlyOwner {
    address receiver = address(this);
    bytes memory params = abi.encode(token1, token2, kyberFirst);
    LENDING_POOL.flashLoan(
        receiver,
        asset,
        amount,
        params
    );
}

function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address initiator,
    bytes calldata params
) external override returns (bool) {
    (address token1, address token2, bool kyberFirst) = abi.decode(params, (address, address, bool));

    if (kyberFirst) {
        _swapKyberToUniswap(amount, token1, token2);
    } else {
        _swapUniswapToKyber(amount, token1, token2);
    }

    uint256 totalDebt = amount + premium;
    IERC20(asset).approve(address(LENDING_POOL), totalDebt);
    return true;
}

function _swapKyberToUniswap(uint amount, address srcTokenAddress, address dstTokenAddress) internal {
    IERC20 srcToken = IERC20(srcTokenAddress);
    IERC20 dstToken = IERC20(dstTokenAddress);

    IKyberNetworkProxy kyber = IKyberNetworkProxy(kyberAddress);
    srcToken.approve(address(kyber), amount);
    (uint rate, ) = kyber.getExpectedRate(srcToken, dstToken, amount);
    kyber.swapTokenToToken(srcToken, amount, dstToken, rate);

    IUniswap uniswap = IUniswap(uniswapAddress);
    uint dstBalance = dstToken.balanceOf(address(this));
    dstToken.approve(address(uniswap), dstBalance);
    address ;
    path[0] = dstTokenAddress;
    path[1] = srcTokenAddress;
    uint[] memory amounts = uniswap.getAmountsOut(dstBalance, path);
    uniswap.swapExactTokensForTokens(dstBalance, amounts[1], path, address(this), now);
}

function _swapUniswapToKyber(uint amount, address srcTokenAddress, address dstTokenAddress) internal {
    IERC20 srcToken = IERC20(srcTokenAddress);
    IERC20 dstToken = IERC20(dstTokenAddress);

    IUniswap uniswap = IUniswap(uniswapAddress);
    srcToken.approve(address(uniswap), amount);
    address[] memory path = new address[](2);
    path[0] = srcTokenAddress;
    path[1] = dstTokenAddress;
    uint[] memory amounts = uniswap.getAmountsOut(amount, path);
    uniswap.swapExactTokensForTokens(amount, amounts[1], path, address(this), now);

    IKyberNetworkProxy kyber = IKyberNetworkProxy(kyberAddress);
    uint dstBalance = dstToken.balanceOf(address(this));
    dstToken.approve(address(kyber), dstBalance);
    (uint rate, ) = kyber.getExpectedRate(dstToken, srcToken, dstBalance);
    kyber.swapTokenToToken(dstToken, dstBalance, srcToken, rate);
}

function withdrawTokens(address token) external onlyOwner {
    uint bal = IERC20(token).balanceOf(address(this));
    require(IERC20(token).transfer(msg.sender, bal), "Transfer failed");
}

function withdrawETH() external onlyOwner {
    msg.sender.transfer(address(this).balance);
}

receive() external payable {}

}

