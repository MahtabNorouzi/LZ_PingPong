// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { OApp, Origin, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract MyOApp is OApp, OAppOptionsType3 {
    using OptionsBuilder for bytes;

    string public lastMessage;

    /// Message kinds for payload
    uint16 public constant SEND = 1;
    uint16 public constant RECEIVED = 2;

    /// Restricts function to be callable only by this contract via external self-call
    error OnlySelf();

    modifier onlySelf() {
        if (msg.sender != address(this)) revert OnlySelf();
        _;
    }

    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) Ownable(_owner) {}

    function quoteSendString(
        uint32 _dstEid,
        string calldata _string,
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(uint8(SEND), _string);

        // Merge owner enforced with caller provided options
        bytes memory merged = bytes.concat(enforcedOptions[_dstEid][SEND], _options);

        fee = _quote(_dstEid, _message, merged, _payInLzToken);
    }


    function sendString(uint32 _dstEid, string calldata _string, bytes calldata _options) external payable {
        bytes memory payload = abi.encode(uint8(SEND), _string);
        bytes memory merged = bytes.concat(enforcedOptions[_dstEid][SEND], _options);
        _lzSend(
            _dstEid,
            payload,
            merged,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
    }


    // Payable external wrapper that lets the contract attach ETH when calling internal _lzSend.
    // Used from inside lzReceive via external self-call to set `msg.value = fee.nativeFee`.
    // Without this, `lzReceive` would inherit a tiny msg.value (e.g., from native drop), causing NotEnoughNative.
    function _sendWithValue(
        uint32 dstEid,
        bytes calldata message,
        bytes calldata options,
        MessagingFee calldata fee,
        address refund
    ) external payable onlySelf{
        _lzSend(dstEid, message, options, fee, payable(refund));
    }


    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        (uint8 kind, string memory text) = abi.decode(_message, (uint8, string));
        lastMessage = text;

        if (kind == SEND) {
            bytes memory encodedMsg = abi.encode(uint8(RECEIVED), "message received");

            bytes memory replyOpts = OptionsBuilder.newOptions().addExecutorLzReceiveOption(900000, 0);
            bytes memory merged = bytes.concat(enforcedOptions[_origin.srcEid][RECEIVED], replyOpts);

            // Quote reply fee in native
            MessagingFee memory q2 = _quote(_origin.srcEid, encodedMsg, merged, false);

            // Ensure the contract has enough ETH to fund the reply
            require(address(this).balance >= q2.nativeFee, "insufficient balance for reply");

            // External self-call to create a new payable frame with msg.value = q2.nativeFee
            this._sendWithValue{ value: q2.nativeFee }(
                _origin.srcEid,
                encodedMsg,
                merged,
                q2,
                address(this)
            );
        }
    }

    receive() external payable {}
}