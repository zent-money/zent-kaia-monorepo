// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IZentPayLink {
    struct Invoice {
        address merchant;
        address token; // address(0) = native KAIA
        uint256 amount; // 0 = variable
        uint64 expiry;
        string metadataURI; // off-chain description
        uint256 paid; // total paid
        bool closed;
    }

    event InvoiceCreated(uint256 indexed id, address indexed merchant);
    event InvoicePaid(uint256 indexed id, address indexed payer, uint256 amount, uint256 fee);
    event InvoiceClosed(uint256 indexed id);

    function createInvoice(address token, uint256 amount, uint64 expiry, string calldata metadataURI)
        external
        returns (uint256);
    function pay(uint256 id, uint256 amount, address payer) external payable;
    function close(uint256 id) external;
    function getInvoice(uint256 id) external view returns (Invoice memory);
}
