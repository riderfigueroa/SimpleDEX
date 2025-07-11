// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SimpleDEX
/// @notice  Contrato de intercambio con fórmula de producto constante entre TokenA y TokenB
contract SimpleDEX is Ownable {
    IERC20 public tokenA;
    IERC20 public tokenB;

    event TokenSwapped(address indexed user, string direction, uint256 amountIn, uint256 amountOut);
    event LiquidityAdded(address indexed provider, uint256 amountTokenA, uint256 amountTokenB);
    event LiquidityRemoved(address indexed to, uint256 amountTokenA, uint256 amountTokenB);

    constructor(address _tokenA, address _tokenB) Ownable(msg.sender) {
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token address");
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    /// @notice Permite agregar liquidez al contrato
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    /// @notice Permite al owner retirar liquidez del contrato
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA <= tokenA.balanceOf(address(this)), "Not enough TokenA");
        require(amountB <= tokenB.balanceOf(address(this)), "Not enough TokenB");

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }
     /// @notice Intercambia TokenA por TokenB de manera constante usando la formula dy = (dx * y) / (x + dx);
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Amount must be > 0");

        uint256 disponibleA = tokenA.balanceOf(address(this));
        uint256 disponibleB = tokenB.balanceOf(address(this));
        require(disponibleB > 0 && disponibleA > 0, "Empty pool");

        tokenA.transferFrom(msg.sender, address(this), amountAIn);

        uint256 amountOut = (amountAIn * disponibleB) / (disponibleA + amountAIn);

        require(amountOut <= disponibleB, "Insufficient TokenB liquidity");
        tokenB.transfer(msg.sender, amountOut);

        emit TokenSwapped(msg.sender, "AtoB", amountAIn, amountOut);
    }
     /// @notice Intercambia TokenB por TokenA de manera constante usando la formula dy = (dx * y) / (x + dx);
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Amount must be > 0");

        uint256 disponibleA = tokenA.balanceOf(address(this));
        uint256 disponibleB = tokenB.balanceOf(address(this));
        require(disponibleA > 0 && disponibleB > 0, "Empty pool");

        tokenB.transferFrom(msg.sender, address(this), amountBIn);

        uint256 amountOut = (amountBIn * disponibleA) / (disponibleB + amountBIn);

        require(amountOut <= disponibleA, "Insufficient TokenA liquidity");
        tokenA.transfer(msg.sender, amountOut);

        emit TokenSwapped(msg.sender, "BtoA", amountBIn, amountOut);
    }
    /// @notice Retorna el precio estimado 1 unidad del token contrario con 18 decimales
    function getPrice(address _token) external view returns (uint256) {
        uint256 disponibleA = tokenA.balanceOf(address(this));
        uint256 disponibleB = tokenB.balanceOf(address(this));

        require(_token == address(tokenA) || _token == address(tokenB), "Invalid token");

        if (_token == address(tokenA)) {
            require(disponibleA > 0, "No TokenA liquidity");
            return (disponibleB * 1e18) / disponibleA;
        } else {
            require(disponibleB > 0, "No TokenB liquidity");
            return (disponibleA * 1e18) / disponibleB;
        }
    }
}
