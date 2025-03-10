// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/SE2Token.sol";

contract GameTest is Test {
    Game public gameContract;
    address public player1;
    address public player2;
    address public gameAdmin;
    address public owner;

    string constant METADATA_URI = "ipfs://bafkreib4gjvonnypiwsprt75jjwayubqnq7sjlmb56elvz5sjapnsupqbm";

    function setUp() public {
        owner = vm.addr(1);
        gameAdmin = vm.addr(2);
        player1 = vm.addr(3);
        player2 = vm.addr(4);

        vm.startPrank(owner);
        gameContract = new Game();
        vm.stopPrank();

        vm.startPrank(owner);
        gameContract.setGameAdmin(gameAdmin, true);
        vm.stopPrank();
    }

    function testDeployment() public view {
        address contractAddress = address(gameContract);
        assertNotEq(contractAddress, address(0), "Contract not deployed");
        assertEq(gameContract.owner(), owner, "Owner is not correct");
    }

    function testSetGameAdmin() public view {
        assertTrue(gameContract.gameAdmins(gameAdmin), "Game admin not set");
    }

    function testUpdateScore() public {
        vm.startPrank(gameAdmin);
        gameContract.updateScore(player1, 10);
        vm.stopPrank();
        uint256 score = gameContract.getPlayerScore(player1);
        assertEq(score, 10, "Score not updated correctly");

        vm.startPrank(owner);
        gameContract.updateScore(player2, 5);
        vm.stopPrank();
        score = gameContract.getPlayerScore(player2);
        assertEq(score, 5, "Owner can also update score");
    }

    function testMintNFT() public {
        uint256 levelId = 1;

        vm.startPrank(gameAdmin);
        uint256 tokenId = gameContract.mintNFT(player1, levelId, METADATA_URI);
        vm.stopPrank();

        assertTrue(gameContract.hasCompletedLevel(player1, levelId), "Level not marked as completed");
        assertEq(gameContract.ownerOf(tokenId), player1, "NFT not minted to player");
        assertEq(gameContract.tokenURI(tokenId), METADATA_URI, "Metadata URI not set");
    }

    function testMintNFT_LevelAlreadyCompleted() public {
        uint256 levelId = 1;
        vm.startPrank(gameAdmin);
        gameContract.mintNFT(player1, levelId, METADATA_URI);
        vm.stopPrank();

        vm.startPrank(gameAdmin);
        vm.expectRevert("Level already completed");
        gameContract.mintNFT(player1, levelId, METADATA_URI);
        vm.stopPrank();
    }


    function testOnlyGameAdmin_UpdateScore() public {
        vm.startPrank(player1);
        vm.expectRevert("Not authorized");
        gameContract.updateScore(player1, 10);
        vm.stopPrank();
    }

    function testOnlyGameAdmin_MintNFT() public {
        vm.startPrank(player1);
        vm.expectRevert("Not authorized");
        gameContract.mintNFT(player1, 1, METADATA_URI);
        vm.stopPrank();
    }
} 