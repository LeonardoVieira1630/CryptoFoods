// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CryptoFoods
/// @notice A contract for managing soulbound tokens with scores
contract CryptoFoods is ERC1155, ERC1155Burnable, Ownable {
    ///////////////////////////////////////////////////////////////////
    /// @notice STRUCTS, MAPPINGS, and STATE VARIABLES
    ///////////////////////////////////////////////////////////////////

    struct TokenInfo {
        string metadataURI; // Metadata URI for the token
        uint256 score; // Score associated with the token
    }

    mapping(uint256 => TokenInfo) public tokenInfo; // Token details for each tokenId
    mapping(address => uint256) public userScores; // Total score for each user
    uint256 public currentTokenId; // Tracks the latest tokenId

    /////////////////////////////////////////////////////////////////////////////////////////////////
    /// @notice EVENTS
    /////////////////////////////////////////////////////////////////////////////////////////////////

    event TokenCreated(uint256 indexed tokenId, string metadataURI);
    event TokenMinted(address indexed to, uint256 tokenId, uint256 amount, uint256 score);

    /////////////////////////////////////////////////////////////////////////////////////////////////
    /// @notice CONSTRUCTOR
    /////////////////////////////////////////////////////////////////////////////////////////////////

    constructor() ERC1155("https://ipfs.io/ipfs/QmR4zPgakFphHvojPz2iKWoBiQzwMttWaCDXBM7zkX9d1K/{id}.json") Ownable(msg.sender) {
        // Create and mint the initial three tokens
        string[3] memory uris = [
            "https://ipfs.io/ipfs/QmR4zPgakFphHvojPz2iKWoBiQzwMttWaCDXBM7zkX9d1K/1.json",
            "https://ipfs.io/ipfs/QmR4zPgakFphHvojPz2iKWoBiQzwMttWaCDXBM7zkX9d1K/2.json",
            "https://ipfs.io/ipfs/QmR4zPgakFphHvojPz2iKWoBiQzwMttWaCDXBM7zkX9d1K/3.json"
        ];
        
        uint256[3] memory scores = [uint256(100), uint256(100), uint256(150)]; // Define scores for each token
        
        for (uint256 i = 0; i < 3; i++) {
            currentTokenId++;
            
            // Create token
            tokenInfo[currentTokenId] = TokenInfo(uris[i], scores[i]);
            emit TokenCreated(currentTokenId, uris[i]);
            
            // Mint token
            _mint(msg.sender, currentTokenId, 1, "");
            userScores[msg.sender] += scores[i];
            emit TokenMinted(msg.sender, currentTokenId, 1, scores[i]);
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    /// @notice TOKEN MANAGEMENT FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Create a new token with a specific score
    /// @param metadataURI The URI for the token's metadata
    /// @param score The score associated with the token
    /// @return tokenId The ID of the newly created token
    function createToken(string memory metadataURI, uint256 score) external onlyOwner returns (uint256) {
        currentTokenId++;

        tokenInfo[currentTokenId] = TokenInfo(metadataURI, score);

        emit TokenCreated(currentTokenId, metadataURI);
        return currentTokenId;
    }

    /// @notice Mint a new token for an address and update user score
    /// @param to The recipient of the token
    /// @param tokenId The ID of the token to mint
    /// @param amount The number of tokens to mint
    function mint(address to, uint256 tokenId, uint256 amount) external onlyOwner {
        require(bytes(tokenInfo[tokenId].metadataURI).length > 0, "Token ID does not exist");
        _mint(to, tokenId, amount, "");

        // Update user score
        uint256 tokenScore = tokenInfo[tokenId].score;
        userScores[to] += tokenScore * amount;

        emit TokenMinted(to, tokenId, amount, tokenScore);
    }

    /// @notice Get the total score of a user
    /// @param user The address of the user
    /// @return The total score of the user
    function getUserScore(address user) external view returns (uint256) {
        return userScores[user];
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    /// @notice TOKEN TRANSFER RESTRICTIONS
    /////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Override to prevent single transfers (soulbound tokens)
    function safeTransferFrom(
        address, /*from*/
        address, /*to*/
        uint256, /*id*/
        uint256, /*amount*/
        bytes memory /*data*/
    ) public virtual override {
        revert("Tokens are soulbound and cannot be transferred");
    }

    /// @notice Override to prevent batch transfers (soulbound tokens)
    function safeBatchTransferFrom(
        address, /*from*/
        address, /*to*/
        uint256[] memory, /*ids*/
        uint256[] memory, /*amounts*/
        bytes memory /*data*/
    ) public virtual override {
        revert("Tokens are soulbound and cannot be transferred");
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    /// @notice TOKEN BURN FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Burn a token and update the user's score
    /// @param account The address of the token holder
    /// @param id The ID of the token to burn
    /// @param value The number of tokens to burn
    function burn(address account, uint256 id, uint256 value) public virtual override {
        if (account != _msgSender() && !isApprovedForAll(account, _msgSender())) {
            revert ERC1155MissingApprovalForAll(_msgSender(), account);
        }
        userScores[account] -= tokenInfo[id].score * value;
        _burn(account, id, value);
    }

    /// @notice Prevent batch burning
    function burnBatch(address, /*account*/ uint256[] memory, /*ids*/ uint256[] memory /*values*/ )
        public
        virtual
        override
    {
        revert("Tokens cannot be burned in batch");
    }

    /// @notice Override the uri function to return the correct metadata URI for each token
    /// @param tokenId The ID of the token
    /// @return The metadata URI for the token
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(bytes(tokenInfo[tokenId].metadataURI).length > 0, "URI query for nonexistent token");
        return tokenInfo[tokenId].metadataURI;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
}
