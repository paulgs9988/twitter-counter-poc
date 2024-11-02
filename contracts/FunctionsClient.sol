// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFunctionsRouter {
    function sendRequest(
        uint64 subscriptionId,
        bytes calldata data,
        uint32 gasLimit,
        bytes32 donId
    ) external returns (bytes32);
}

abstract contract FunctionsClient {
    address private immutable i_router;

    event RequestSent(bytes32 indexed id);
    event RequestFulfilled(bytes32 indexed id);

    constructor(address router) {
        require(router != address(0), "Router cannot be zero address");
        i_router = router;
    }

    function _sendRequest(
        bytes memory request,
        uint64 subscriptionId,
        uint32 gasLimit,
        bytes32 donId
    ) internal virtual returns (bytes32) {
        bytes32 requestId = IFunctionsRouter(i_router).sendRequest(
            subscriptionId,
            request,
            gasLimit,
            donId
        );
        
        emit RequestSent(requestId);
        return requestId;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal virtual;

    // Add this function to receive the callback from the router
    function handleOracleFulfillment(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) external {
        require(msg.sender == i_router, "Only router can fulfill");
        fulfillRequest(requestId, response, err);
        emit RequestFulfilled(requestId);
    }
}