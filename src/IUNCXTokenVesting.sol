// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

interface IUNCXTokenVesting {
    struct TokenLock {
        address tokenAddress; // The token address
        uint256 sharesDeposited; // the total amount of shares deposited
        uint256 sharesWithdrawn; // amount of shares withdrawn
        uint256 startEmission; // date token emission begins
        uint256 endEmission; // the date the tokens can be withdrawn
        uint256 lockID; // lock id per token lock
        address owner; // the owner who can edit or withdraw the lock
        address condition; // address(0) = no condition, otherwise the condition contract must implement IUnlockCondition
    }

    struct LockParams {
        address payable owner; // the user who can withdraw tokens once the lock expires.
        uint256 amount; // amount of tokens to lock
        uint256 startEmission; // 0 if lock type 1, else a unix timestamp
        uint256 endEmission; // the unlock date as a unix timestamp (in seconds)
        address condition; // address(0) = no condition, otherwise the condition must implement IUnlockCondition
    }

    function LOCKS(uint256 _lockID) external view returns (TokenLock memory);

    function NONCE() external view returns (uint256);
    /**
     * @notice Creates one or multiple locks for the specified token
     * @param _token the erc20 token address
     * @param _lock_params an array of locks with format: [LockParams[owner, amount, startEmission, endEmission, condition]]
     * owner: user or contract who can withdraw the tokens
     * amount: must be >= 100 units
     * startEmission = 0 : LockType 1
     * startEmission != 0 : LockType 2 (linear scaling lock)
     * use address(0) for no premature unlocking condition
     * Fails if startEmission is not less than EndEmission
     * Fails is amount < 100
     */
    function lock(address _token, LockParams[] calldata _lock_params) external;

    /**
     * @notice withdraw a specified amount from a lock. _amount is the ideal amount to be withdrawn.
     * however, this amount might be slightly different in rebasing tokens due to the conversion to shares,
     * then back into an amount
     * @param _lockID the lockID of the lock to be withdrawn
     * @param _amount amount of tokens to withdraw
     */
    function withdraw(uint256 _lockID, uint256 _amount) external;

    /**
     * @notice extend a lock with a new unlock date, if lock is Type 2 it extends the emission end date
     */
    function relock(uint256 _lockID, uint256 _unlock_date) external;

    /**
     * @notice increase the amount of tokens per a specific lock, this is preferable to creating a new lock
     * Its possible to increase someone elses lock here it does not need to be your own, useful for contracts
     */
    function incrementLock(uint256 _lockID, uint256 _amount) external;

    /**
     * @notice transfer a lock to a new owner, e.g. presale project -> project owner
     * Please be aware this generates a new lock, and nulls the old lock, so a new ID is assigned to the new lock.
     */
    function transferLockOwnership(
        uint256 _lockID,
        address payable _newOwner
    ) external;

    /**
     * @notice split a lock into two seperate locks, useful when a lock is about to expire and youd like to relock a portion
     * and withdraw a smaller portion
     * Only works on lock type 1, this feature does not work with lock type 2
     * @param _amount the amount in tokens
     */
    function splitLock(uint256 _lockID, uint256 _amount) external;

    /**
     * @notice migrates to the next locker version, only callable by lock owners
     */
    function migrate(uint256 _lockID, uint256 _option) external;

    /**
     * @notice premature unlock conditions can be malicous (prevent withdrawls by failing to evalaute or return non bools)
     * or not give community enough insurance tokens will remain locked until the end date, in such a case, it can be revoked
     */
    function revokeCondition(uint256 _lockID) external;

    // test a condition on front end, added here for convenience in UI, returns unlockTokens() bool, or fails
    function testCondition(address condition) external;

    // returns withdrawable share amount from the lock, taking into consideration start and end emission
    function getWithdrawableShares(
        uint256 _lockID
    ) external view returns (uint256);

    // convenience function for UI, converts shares to the current amount in tokens
    function getWithdrawableTokens(
        uint256 _lockID
    ) external view returns (uint256);

    // For UI use
    function convertSharesToTokens(
        address _token,
        uint256 _shares
    ) external view returns (uint256);

    function convertTokensToShares(
        address _token,
        uint256 _tokens
    ) external view returns (uint256);
}
