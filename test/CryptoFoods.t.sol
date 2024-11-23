// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/main.sol";

contract CryptoFoodsTest is Test {
    CryptoFoods public cryptoFoods;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // Deploy contract with base URI
        cryptoFoods = new CryptoFoods("https://api.cryptofoods.com/");
    }

    function testCreateToken() public {
        // Create a new token
        uint256 tokenId = cryptoFoods.createToken("ipfs://QmHash1", 100);

        // Verify token creation
        (string memory uri, uint256 score) = cryptoFoods.tokenInfo(tokenId);
        assertEq(score, 100);
        assertEq(uri, "ipfs://QmHash1");
        assertEq(tokenId, 1);
    }

    function testCreateTokenUnauthorized() public {
        // Try to create token from unauthorized address
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        cryptoFoods.createToken("ipfs://QmHash1", 100);
    }

    function testMintToken() public {
        // Create and mint token
        uint256 tokenId = cryptoFoods.createToken("ipfs://QmHash1", 100);
        cryptoFoods.mint(user1, tokenId, 1);

        // Verify minting and score
        assertEq(cryptoFoods.balanceOf(user1, tokenId), 1);
        assertEq(cryptoFoods.getUserScore(user1), 100);
    }

    function testMintNonexistentToken() public {
        // Try to mint non-existent token
        vm.expectRevert("Token ID does not exist");
        cryptoFoods.mint(user1, 1, 1);
    }

    function testPreventTransfer() public {
        // Create and mint token
        uint256 tokenId = cryptoFoods.createToken("ipfs://QmHash1", 100);
        cryptoFoods.mint(user1, tokenId, 1);

        // Try to transfer (should fail)
        vm.prank(user1);
        vm.expectRevert("Tokens are soulbound and cannot be transferred");
        cryptoFoods.safeTransferFrom(user1, user2, tokenId, 1, "");
    }

    function testBurnToken() public {
        // Create and mint token
        uint256 tokenId = cryptoFoods.createToken("ipfs://QmHash1", 100);
        cryptoFoods.mint(user1, tokenId, 1);

        // Burn token
        vm.prank(user1);
        cryptoFoods.burn(user1, tokenId, 1);

        // Verify burn and score update
        assertEq(cryptoFoods.balanceOf(user1, tokenId), 0);
        assertEq(cryptoFoods.getUserScore(user1), 0);
    }

    function testPreventBatchBurn() public {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        vm.expectRevert("Tokens cannot be burned in batch");
        cryptoFoods.burnBatch(user1, ids, amounts);
    }

    function testMultipleTokensScore() public {
        // Create and mint multiple tokens
        uint256 token1 = cryptoFoods.createToken("ipfs://QmHash1", 100);
        uint256 token2 = cryptoFoods.createToken("ipfs://QmHash2", 150);

        cryptoFoods.mint(user1, token1, 1);
        cryptoFoods.mint(user1, token2, 1);

        // Verify total score
        assertEq(cryptoFoods.getUserScore(user1), 250);
    }
}
