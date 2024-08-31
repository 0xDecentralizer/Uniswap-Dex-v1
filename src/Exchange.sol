// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract Exchange is ERC20 {
    address public tokenAddress;

    // Exchange is inheriting ERC20, because our exchange itself is an ERC-20 contract
    // as it is responsible for minting and issuing LP Tokens
    constructor(address token) ERC20("ETH TOKEN LP Token", "lpETHTOKEN") {
        require(token != address(0), "Token address passed is a null address");
        tokenAddress = token;        
    }

    // getReserve returns the balance of `token` held by `this` contract
    function getReserve() view public returns (uint256) {
        return ERC20(tokenAddress).balanceOf(address(this));
    }

    // addLiquidity allows users to add liquidity to the exchange
    function addLiquidity(
        uint256 amountOfToken
    ) public payable returns (uint256) {
        uint256 lpTokensToMint;
        uint256 ethReserveBalance = address(this).balance ;
        uint256 tokenReserveBalance = getReserve();

        ERC20 token = ERC20(tokenAddress);

        // If the reserve is empty, take any user supplied value for initial liquidity
        if (tokenReserveBalance == 0) {
            // Transfer the token from the user to the exchange
            token.transferFrom(msg.sender, address(this), amountOfToken);

            // lpTokensToMint = ethReserveBalance = msg.value
            lpTokensToMint = ethReserveBalance;

            // Mint LP tokens to the user
            _mint(msg.sender, lpTokensToMint);

            return lpTokensToMint;
        }

        // If the reserve is not empty, calculate the amount of LP Tokens to be minted
        uint256 ethReservePriorToFunctionCall = ethReserveBalance - msg.value;
        uint256 minTokenAmountRequire = (msg.value * tokenReserveBalance) / 
            ethReservePriorToFunctionCall;
        require(amountOfToken >= minTokenAmountRequire,
            "Insufficient amount of tokens provided"
        );
        
        // Transfer the token from the user to the exchange
        token.transferFrom(msg.sender, address(this), minTokenAmountRequire);

        // Calculate the amount of LP tokens to be minted
        lpTokensToMint = 
            (totalSupply() * msg.value) /
            ethReservePriorToFunctionCall;

        // Mint LP tokens to the user
        _mint(msg.sender, lpTokensToMint);

        return lpTokensToMint;
    }

    // removeLiquidity allows user to remove their liquidities from the exvhange (pool)
    function removeLiquidity(
        uint256 amountOfLPTokens
    ) public returns(uint256, uint256) {
        // Check that user want to remove >0 LP tokens
        require(
            amountOfLPTokens > 0,
            "Amount of token to remove must be greater than 0"
        );

        uint256 ethReserveBalance = address(this).balance;
        uint256 lpTokenTotalSupply = totalSupply();

        // Calculate the amount of ETH and Tokens to return to the user
        uint256 ethToReturn = (ethReserveBalance * amountOfLPTokens) / 
            lpTokenTotalSupply;
        uint256 tokenToReturn = (totalSupply() * amountOfLPTokens) / 
            lpTokenTotalSupply;

        // Burn the LP tokens from the user, and transfer the ETH and token to the user
        _burn(msg.sender, amountOfLPTokens);
        payable(msg.sender).transfer(ethToReturn);
        ERC20(tokenAddress).transfer(msg.sender, tokenToReturn);
        
        return (ethToReturn, tokenToReturn);
    }

    // getOutputAmountFromSwap calculates the amount of output tokens to be received based on xy = (x + dx)(y - dy)
    function getOutputAmountFromSwap(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(
            inputReserve >= 0 && outputReserve >= 0,
            "Reserves must be greater than 0"
        );

        uint256 inputAmountWithFee = (inputAmount * 99);

        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
    }
}