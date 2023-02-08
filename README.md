# ECOx Lockup

The solidity contracts for ECOx lockups, including the employee variant

## Background

These contracts are designed to hold tokens until they are to be released to their beneficiaries according a preset vesting schedule, while allowing beneficiaries to stake and delegate the tokens such that they can still be used in governance. The employee variant has one cliff and can receive tokens throughout, while the non-employee variant has several cliffs and is created with all tokens intended to be distributed to its beneficiary. Both variants also contain a clawback method that enables the admin to reclaim unvested tokens - beneficiary protection from this behavior must necessarily lie off-chain.

---
## API

### ECOxLockupVault
 - inherits ChunkedVestingVault

This contract is to be initialized with its beneficiary and with all vestable tokens deposited on initialization. The contract allows the beneficiary to stake and vote with all of their tokens, and also delegate their voting power as they see fit. Tokens will become available for withdrawal in amounts and at times defined at initialization. Unvested tokens can be clawed back by an admin.

---
#### Events

##### Unstaked
Attributes:
 - `amount` (uint256): the amount of token unstaked

Emitted when beneficiary unstakes tokens

##### Staked
Attributes: 
 - `amount` (uint256) - the amount of token staked

Emitted when beneficiary stakes tokens

#### stake
Arguments:
 - amount (uint256) - the amount of ECOx to stake

Stakes ECOx in the lockup contract

##### Security Notes
 - reverts when called by not beneficiary
 - reverts if amount is greater than the vault balance

#### delegate
Arguments:
 - who (address) - the address to delegate to

Delegates staked ECOx to a chosen recipient. Uses non-primary delegation, so any future funds sent to the vault will have to be individually delegated.

##### Security Notes
 - reverts when called by not beneficiary

#### unstake
Arguments:
 - amount (uint256) - the amount of ECOx to unstake

Unstakes any lockedup staked ECOx that hasn't already been unstaked

##### Security Notes
 - reverts when called by not beneficiary
 - reverts (in _unstake) if amount is greater than the total staked balance of the lockup

#### clawback
Arguments: None

Allows admin to reclaim any unvested tokens

##### Security Notes
 - only callable by admin
 - does not allow for reclaiming of tokens already vested by beneficiary

#### unvested
Arguments: None

Returns amount of unvested tokens

### ECOxEmployeeLockup
 - inherits `ECOxLockupVault`

Employee variant of lockup contract. This contract is designed to be initialized with an employee as the beneficiary and containing no tokens at time of creation. The contract can (and should) receive tokens throughout and should release them all at the predetermined cliff timestamp

#### vestedOn
Arguments:
 - timestamp (uint256) - The time for which vested tokens are being calculated

Calculates tokens vested at a given timestamp

#### _delegate
Arguments:
 - who (address) - the address to delegate to

Delegates staked ECOx to a chosen recipient. Uses primary delegation, so any future funds sent to the vault will automatically be delegated to the recipient.

#### onClaim
Arguments:
 - amount (uint256) - amount of vested tokens being claimed

Helper function unstaking required tokens before they are claimed

### ECOxEmployeeLockupFactory

Factory contract to create employee lockups.

#### createVault
Arguments:
 - beneficiary (address) - The address who will receive tokens
 - admin (address) - The address that can claw back unvested funds
 - timestamp (uint256) - The cliff timestamp at which tokens vest

Creates a new employee vesting vault. Employees must delegate and stake the funds on their own, since the vault is empty on initialization.

### ECOxLockupVaultFactory

Factory contract to create lockups.

#### createVault
Arguments:
 - beneficiary (address) - The address who will receive tokens
 - admin (address) - The address that can claw back unvested funds
 - amounts (uint256 array) - The array of amounts to be vested at times in the timestamps array
 - timestamps (uint256 array) - The array of vesting timestamps for tokens in the amounts array

Creates a new vesting vault. The vault's tokens are staked by default, and its voting power delegated to the beneficiary. This vault does not use primary delegation, so any further tokens sent to it after initialization must be staked and delegated if their voting power is to be usable.

## Usage
To get project to play nice with VS code, you need to remap all the dependencies so that VS can link them in the editor. You'll need to do this whenever you add new dependencies to the project.

```
yarn remap
```
