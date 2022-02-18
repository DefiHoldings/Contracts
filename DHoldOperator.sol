// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Context.sol"; 
import "@openzeppelin/contracts/utils/Address.sol"; 
import "./DHold.sol";
import "./MultisigWallet.sol";


contract DHolpOperator is Context {

    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private _floorbalance;
    uint256 private _totalSupply;

    DHold private _dHold;
    EnumerableSet.AddressSet private _operators;
    EnumerableSet.AddressSet private _subOperators;

    constructor(address[] memory operators, address payable dhold, uint256 floorbalance) {
        for(uint8 i = 0; i < operators.length; i++) {
            _operators.add(operators[i]);
        }
        _dHold = DHold(dhold);
        _totalSupply = _dHold.totalSupply();
        _floorbalance = floorbalance;
    }


    modifier onlyOperator {
        require(_operators.contains(_msgSender()), "not opt");
        _;
    }

    modifier onlyAnyOperator {
        require(_operators.contains(_msgSender()) || _subOperators.contains(_msgSender()), "not all opt");
        _;
    }

    ///@notice contract functions
    function addOperator(address newOperator) external onlyOperator {
        require(_operators.add(newOperator), "unable to add opt");
    }

    function removeOperator(address operator) external onlyOperator {
        require(_msgSender() != operator, "cannot renounce");
        require(_operators.remove(operator), "unable to remove opt");
    }

    function addSubOperator(address newSubOperator) external onlyOperator {
        require(_subOperators.add(newSubOperator), "unable to add sub opt");
    }

    function removeSubOperator(address subOperator) external onlyOperator {
        require(_subOperators.remove(subOperator), "unable to remove sub opt");
    }

    function setDHold(address payable dHold) external onlyOperator {
        _dHold = DHold(dHold);
        _totalSupply = _dHold.totalSupply();
    }

    function setFloorBalance(uint256 floorbalance) external onlyOperator {
        _floorbalance = floorbalance;
    }


    ///@notice Only Operator Functions 
    ///we wont be adding all functions as they are not needed anymore
    ///this adds a security layer on top of the token 
    function transferOwnership(address newOwner) external onlyOperator {
        require(newOwner != address(0), "new owner address is 0");
        _dHold.transferOwnership(newOwner);
    }

    function addReflectionExcluded(address account) external onlyOperator {
        _dHold.addReflectionExcluded(account);
    }

    function removeReflectionExcluded(address account) external onlyOperator {
        _dHold.removeReflectionExcluded(account);
    }

    function addTaxExcluded(address account) external onlyOperator {
        _dHold.addTaxExcluded(account);
    }

    function removeTaxExcluded(address account) external onlyOperator {
        _dHold.removeTaxExcluded(account);
    }

    function removeBot(address account) external onlyOperator {
        _dHold.removeBot(account);
    }

    function claimExcludedReflections(address from) external onlyOperator {
        _dHold.claimExcludedReflections(from);
    }

    function setSwapFees(bool swapFees) external onlyOperator {
        _dHold.setSwapFees(swapFees);
    }

    ///@notice Only AnyOperator functions
    ///@dev checks if the amount to be swapped doesnt go below floorBalance
    function setMaxTransferAndSwap(uint256 previousMaxTransfer, uint256 newMaxTransfer) external onlyAnyOperator {
        uint256 maxTxAmount = _totalSupply * newMaxTransfer / 1000;
        require(_dHold.balanceOf(address(_dHold)) - maxTxAmount > _floorbalance, "not enough");

        _dHold.setMaxTransfer(newMaxTransfer);
        _dHold.swapAll();
        _dHold.setMaxTransfer(previousMaxTransfer);
    }

    

    function setMaxTransfer(uint256 newMaxTransfer) external onlyAnyOperator {
        _dHold.setMaxTransfer(newMaxTransfer);
    }


    ///@notice any callee functions
    function claimReflection() public {
        _dHold.claimReflection();
    }


    ///@notice function to withdraw ETH from this contract
    function withdrawETH(address payable to) external onlyOperator {
        to.transfer(address(this).balance);
    }

    ///@notice function to withdraw any token balance from this contract
    function withdrawToken(address to, address token) external onlyOperator {
        ERC20(token).transfer(to, ERC20(token).balanceOf(address(this)));
    }

    ///@notice public getters
    function getDHold() external view returns(address) {
        return address(_dHold);
    }

    function getFloorBalance() external view returns (uint256) {
        return _floorbalance;
    }

    function isOperator(address operator) external view returns (bool) {
        return _operators.contains(operator);
    }

    function isSubOperator(address operator) external view returns (bool) {
        return _subOperators.contains(operator);
    }

    function getOperators() external view returns (address[] memory) {
        return _operators.values();
    }

    function getSubOperators() external view returns (address[] memory) {
        return _subOperators.values();
    }


    receive() external payable {}

}