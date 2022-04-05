// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import { StringUtils } from "./libraries/StringUtils.sol";
import { Base64 } from "./libraries/Base64.sol";
import "hardhat/console.sol";

contract Domains is ERC721URIStorage {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address payable public owner;
    string public tld = "learner";

    // We'll be storing our NFT images on chain as SVGs
    string svgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path d="M72.863 42.949c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-10.081 6.032-6.85 3.934-10.081 6.032c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-8.013-4.721a4.52 4.52 0 0 1-1.589-1.616c-.384-.665-.594-1.418-.608-2.187v-9.31c-.013-.775.185-1.538.572-2.208a4.25 4.25 0 0 1 1.625-1.595l7.884-4.59c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v6.032l6.85-4.065v-6.032c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595L41.456 24.59c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-14.864 8.655a4.25 4.25 0 0 0-1.625 1.595c-.387.67-.585 1.434-.572 2.208v17.441c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l10.081-5.901 6.85-4.065 10.081-5.901c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v9.311c.013.775-.185 1.538-.572 2.208a4.25 4.25 0 0 1-1.625 1.595l-7.884 4.721c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-7.884-4.59a4.52 4.52 0 0 1-1.589-1.616c-.385-.665-.594-1.418-.608-2.187v-6.032l-6.85 4.065v6.032c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l14.864-8.655c.657-.394 1.204-.95 1.589-1.616s.594-1.418.609-2.187V55.538c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595l-14.993-8.786z" fill="#fff"/><defs><linearGradient id="B" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#cb5eee"/><stop offset="1" stop-color="#0cd7e4" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = '</text></svg>';

    mapping( uint => string )  names;

    mapping( string => address ) domains;

    mapping( string => string ) records;

    error Unauthorized();
    error AlreadyRegistered();

    constructor() payable ERC721("Learner Name Service", "LNS") {
        owner = payable(msg.sender);
    }

    function price( string calldata _name ) public pure returns (uint) {
        uint len = StringUtils.strlen(_name);
        require(len > 0);

        if( len <= 3 ) 
            return 5 * 10 ** 17; //0.5 matic
        
        else if (len <= 6) 
            return 2 * 10**17; //0.2 matic
        
        else 
            return 1 * 10**17; //0.1 matic
    }


    function register( string calldata _name ) public payable {
        if( domains[_name] != address(0) ) revert AlreadyRegistered();

        uint _price = price(_name);
        require(msg.value >= _price, "Insufficient Matic.");

        // Combine the name passed into the function  with the TLD
        string memory name = string(abi.encodePacked(_name, ".", tld));
        // Create the SVG (image) for the NFT with the name
        string memory finalSvg = string(abi.encodePacked(svgPartOne, name, svgPartTwo));
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(_name);
        string memory strLen = Strings.toString(length);

        console.log("Registering %s.%s on the contract with tokenID %d", _name, tld, newRecordId);

         // Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
        string memory json = Base64.encode(
        abi.encodePacked(
            '{"name": "',
            name,
            '", "description": "A domain on the Learner name service", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(finalSvg)),
            '","length":"',
            strLen,
            '"}'
        )
        );

        string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));

        console.log("\n--------------------------------------------------------");
        console.log("Final tokenURI", finalTokenUri);
        console.log("--------------------------------------------------------\n");

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);
        domains[_name] = msg.sender;

        names[newRecordId] = _name;
        _tokenIds.increment();
    }

    function getAddress( string calldata _name ) public view returns (address) {
        return domains[_name];
    }

    function setRecord( string calldata _name, string calldata _record ) public {
        if (msg.sender != domains[_name]) revert Unauthorized();
        records[_name] = _record;
    }

    function getRecord ( string calldata _name ) public view returns (string memory) {
        return records[_name];
    }

    function getAllNames() public view returns (string[] memory) {
        console.log("Getting all names from contract");
        string[] memory allNames = new string[](_tokenIds.current());
        for (uint i = 0; i < _tokenIds.current(); i++) {
            allNames[i] = names[i];
            console.log("Name for token %d is %s", i, allNames[i]);
        }

        return allNames;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not owner.");
        _;
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw Matic");
    } 

}