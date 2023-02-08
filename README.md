# ECOx Lockup

The solidity contracts for ECOx lockups

## Background

These contracts are designed to hold tokens until they are to be released to their beneficiaries according a preset vesting schedule, while allowing beneficiaries to stake and delegate the tokens such that they can still be used in governance. The cliff variant has a single unlock and has delegation designed to recieve tokens throughout its lifetime, while the chunked variant has several unlockes and is created with all tokens intended to be distributed to its beneficiary. Both variants also contain a clawback method that enables the admin to reclaim unvested tokens, usually in the case of loss of access to the beneficiary address. Beneficiary protection from this behavior must necessarily lie off-chain.

---
## API

### ECOxChunkedLockup
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

Delegates staked ECOx to a chosen recipient. Uses non-primary delegation, so any future funds sent to the vault would require calling this function again.

##### Security Notes
 - reverts when called by not beneficiary

#### unstake
Arguments:
 - amount (uint256) - the amount of ECOx to unstake

Undelegates enough staked ECOx if there is not enough already undelegated.

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

### ECOxCliffLockup
 - inherits `ECOxChunkedLockup`

The single cliff variant of lockup contract. This contract is designed to be initialized containing no tokens at time of creation and with a single chunk release of all funds at the cliff date. The contract can (and should) receive tokens throughout and can even keep recieving tokens after the cliff date.

#### vestedOn
Arguments:
 - timestamp (uint256) - The time for which vested tokens are being calculated

Calculates tokens vested at a given timestamp

#### _delegate
Arguments:
 - who (address) - the address to delegate to

Delegates staked ECOx to a chosen recipient. Uses primary delegation, so any future staked funds will automatically be delegated to the recipient.

#### onClaim
Arguments:
 - amount (uint256) - amount of vested tokens being claimed

Helper function unstaking required tokens before they are claimed

### ECOxCliffLockupFactory

Factory contract to create cliff lockups.

#### createVault
Arguments:
 - beneficiary (address) - The address who will receive tokens
 - admin (address) - The address that can claw back unvested funds
 - timestamp (uint256) - The cliff timestamp at which tokens vest

Creates a new vault. Beneficiaries must delegate and stake the funds on their own, since the vault is empty on initialization.

### ECOxChunkedLockupFactory

Factory contract to create lockups.

#### createVault
Arguments:
 - beneficiary (address) - The address who will receive tokens
 - admin (address) - The address that can claw back unvested funds
 - amounts (uint256 array) - The array of amounts to be vested at times in the timestamps array
 - timestamps (uint256 array) - The array of vesting timestamps for tokens in the amounts array

Creates a new vesting vault. The vault's tokens are staked by default, and its voting power delegated to the beneficiary. This vault does not use primary delegation, so if further tokens are sent to it after initialization, they must be staked and delegated separately.

## Usage
To get project to play nice with VS code, you need to remap all the dependencies so that VS can link them in the editor. You'll need to do this whenever you add new dependencies to the project.

```
yarn remap
```
