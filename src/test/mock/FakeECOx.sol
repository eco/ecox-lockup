pragma solidity ^0.8.0;

import {Policy} from "currency/policy/Policy.sol";
import {IECO} from "currency/currency/IECO.sol";
import {ECOx} from "currency/currency/ECOx.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract FakeECOx is ECOx {

    constructor(address _policy, address _distributor, uint256 _initialSupply, address _ecoAddr, address _initialPauser)
    ECOx(Policy(_policy), _distributor, _initialSupply, IECO(_ecoAddr), _initialPauser)
    {}


    function cheatMint(address to, uint256 amount) external {
        _mint(to, amount);
    }

}