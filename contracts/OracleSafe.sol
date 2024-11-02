// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./FunctionsClient.sol";
import "./FunctionsRequest.sol";

interface ITwitterCounter {
    function updateCounter() external;
    function getCount() external view returns (uint256);
}

contract OracleSafe is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    ITwitterCounter public immutable counter;
    bytes32 public lastRequestId;
    uint256 public lastLikeCount;
    string public tweetId;
    
    // Increase gas limit for Functions call
    uint32 public constant GAS_LIMIT = 500000;
    uint64 public subscriptionId;
    bytes32 public donId;
    address public owner;

    event TweetMonitored(string tweetId);
    event ResponseReceived(bytes32 indexed requestId, uint256 likes);
    event CounterUpdated(uint256 newCount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    receive() external payable {}
    fallback() external payable {}

    constructor(
        address _counterContract,
        uint64 _subscriptionId,
        address _router
    ) FunctionsClient(_router) {
        require(_counterContract != address(0), "Invalid counter address");
        counter = ITwitterCounter(_counterContract);
        subscriptionId = _subscriptionId;
        donId = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
        owner = msg.sender;
    }

    function checkLikes() external payable returns (bytes32) {
        require(bytes(tweetId).length > 0, "Tweet ID not set");
        
        string memory source = string(
            abi.encodePacked(
                "const tweetId = '",
                tweetId,
                "';\n",
                "const apiResponse = await Functions.makeHttpRequest({\n",
                "  url: `https://api.twitter.com/2/tweets/${tweetId}?tweet.fields=public_metrics`,\n",
                "  headers: {\n",
                "    'Authorization': 'Bearer {redacted}%{redacted}%{redacted}'\n",
                "  }\n",
                "});\n",
                "if (apiResponse.error) { throw Error('Request failed'); }\n",
                "const likes = apiResponse.data.data.public_metrics.like_count;\n",
                "return Functions.encodeUint256(likes);\n"
            )
        );

        FunctionsRequest.Request memory req;
        req = req.initializeRequestForInlineJavaScript();
        req = req.addInlineJavaScript(source);

        bytes32 requestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            GAS_LIMIT,
            donId
        );

        lastRequestId = requestId;
        return requestId;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (err.length > 0) {
            emit ResponseReceived(requestId, 0);
            return;
        }

        uint256 likes = abi.decode(response, (uint256));
        
        if (likes > lastLikeCount) {
            uint256 newLikes = likes - lastLikeCount;
            lastLikeCount = likes;
            
            for (uint256 i = 0; i < newLikes; i++) {
                counter.updateCounter();
                emit CounterUpdated(counter.getCount());
            }
        }
        
        emit ResponseReceived(requestId, likes);
    }

    function updateSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        require(_subscriptionId != 0, "Invalid subscription ID");
        subscriptionId = _subscriptionId;
    }

    function updateDonId(bytes32 _donId) external onlyOwner {
        require(_donId != bytes32(0), "Invalid DON ID");
        donId = _donId;
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        (bool success, ) = owner.call{value: balance}("");
        require(success, "ETH transfer failed");
    }
}