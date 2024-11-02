// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFunctionsClient {
    function handleOracleFulfillment(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) external;
}

abstract contract FunctionsClient is IFunctionsClient {
    address private immutable i_router;

    event RequestSent(bytes32 indexed id);
    event RequestFulfilled(bytes32 indexed id);
    event RequestFailed(bytes32 indexed id, bytes response);

    constructor(address router) {
        if (router == address(0)) {
            revert();
        }
        i_router = router;
    }

    function _sendRequest(
        bytes memory request,
        uint64 subscriptionId,
        uint32 gasLimit,
        bytes32 donId
    ) internal virtual returns (bytes32);

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal virtual;

    function handleOracleFulfillment(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) external virtual override {
        if (msg.sender != i_router) {
            revert();
        }
        fulfillRequest(requestId, response, err);
        emit RequestFulfilled(requestId);
    }
}