// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library FunctionsRequest {
    struct Request {
        string sourceCode;
        bytes secrets;
        string[] args;
    }

    function initializeRequestForInlineJavaScript(
        Request memory self
    ) internal pure returns (Request memory) {
        return self;
    }

    function addInlineJavaScript(
        Request memory self,
        string memory sourceCode
    ) internal pure returns (Request memory) {
        self.sourceCode = sourceCode;
        return self;
    }

    function encodeCBOR(Request memory self) internal pure returns (bytes memory) {
        return abi.encode(self.sourceCode);
    }
}