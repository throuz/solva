import "../libraries/system_instruction.sol";

@program_id("DWhjLw1136PfojRSmQoVgJx1kfS6cPtebHuyaZQZ7WX1")
contract solva_deposit {
  address private platformPubKey;
  address private expertPubKey;
  address private clientPubKey;
  uint64 private caseAmountLamports;
  uint64 private expertDepositLamports;
  uint64 private clientDepositLamports;
  uint64 private expirationTimestamp;
  address private indemniteePubKey;
  Status private status;

  enum Status {
    Created,
    Canceled,
    Activated,
    Expired,
    ForceClosed,
    Compensated,
    Completed,
    GotIncome,
    Closed
  }

  @payer(payer)
  constructor(
    address _platformPubKey,
    uint64 _caseAmountLamports,
    uint64 _expertDepositLamports,
    uint64 _clientDepositLamports,
    uint64 _expirationTimestamp
  ) {
    platformPubKey = _platformPubKey;
    expertPubKey = tx.accounts.payer.key;
    caseAmountLamports = _caseAmountLamports;
    expertDepositLamports = _expertDepositLamports;
    clientDepositLamports = _clientDepositLamports;
    expirationTimestamp = _expirationTimestamp;
    if (expertDepositLamports > 0) {
      SystemInstruction.transfer(
        tx.accounts.payer.key,
        tx.accounts.dataAccount.key,
        expertDepositLamports
      );
    }
    status = Status.Created;
  }

  @mutableSigner(signer)
  function expertCancelCase() external {
    require(status == Status.Created);
    require(tx.accounts.signer.key == expertPubKey);
    if (expertDepositLamports > 0) {
      tx.accounts.dataAccount.lamports -= expertDepositLamports;
      tx.accounts.signer.lamports += expertDepositLamports;
    }
    status = Status.Canceled;
  }

  @mutableSigner(signer)
  function clientActivateCase(uint64 _clientDepositLamports) external {
    require(status == Status.Created);
    require(clientDepositLamports == _clientDepositLamports);
    clientPubKey = tx.accounts.signer.key;
    if (clientDepositLamports > 0) {
      SystemInstruction.transfer(
        tx.accounts.signer.key,
        tx.accounts.dataAccount.key,
        clientDepositLamports
      );
    }
    status = Status.Activated;
  }

  @mutableSigner(signer)
  function expertExpireCase() external {
    require(status == Status.Activated);
    require(block.timestamp > expirationTimestamp);
    require(tx.accounts.signer.key == expertPubKey);
    if (expertDepositLamports > 0) {
      tx.accounts.dataAccount.lamports -= expertDepositLamports;
      tx.accounts.signer.lamports += expertDepositLamports;
    }
    if (clientDepositLamports > 0) {
      tx.accounts.dataAccount.lamports -= clientDepositLamports;
      tx.accounts.signer.lamports += clientDepositLamports;
    }
    status = Status.Expired;
  }

  @mutableSigner(signer)
  function platformForceCloseCaseForExpert() external {
    require(status == Status.Activated);
    require(tx.accounts.signer.key == platformPubKey);
    indemniteePubKey = expertPubKey;
    status = Status.ForceClosed;
  }

  @mutableSigner(signer)
  function platformForceCloseCaseForClient() external {
    require(status == Status.Activated);
    require(tx.accounts.signer.key == platformPubKey);
    indemniteePubKey = clientPubKey;
    status = Status.ForceClosed;
  }

  @mutableSigner(signer)
  function indemniteeRecieveCompensation() external {
    require(status == Status.ForceClosed);
    require(tx.accounts.signer.key == indemniteePubKey);
    if (expertDepositLamports > 0) {
      tx.accounts.dataAccount.lamports -= expertDepositLamports;
      tx.accounts.signer.lamports += expertDepositLamports;
    }
    if (clientDepositLamports > 0) {
      tx.accounts.dataAccount.lamports -= clientDepositLamports;
      tx.accounts.signer.lamports += clientDepositLamports;
    }
    status = Status.Compensated;
  }

  @mutableSigner(signer)
  function clientCompleteCase() external {
    require(status == Status.Activated);
    require(tx.accounts.signer.key == clientPubKey);
    SystemInstruction.transfer(
      tx.accounts.signer.key, tx.accounts.dataAccount.key, caseAmountLamports
    );
    if (clientDepositLamports > 0) {
      tx.accounts.dataAccount.lamports -= clientDepositLamports;
      tx.accounts.signer.lamports += clientDepositLamports;
    }
    status = Status.Completed;
  }

  @mutableSigner(signer)
  function expertGetIncome() external {
    require(status == Status.Completed);
    require(tx.accounts.signer.key == expertPubKey);
    tx.accounts.dataAccount.lamports -= caseAmountLamports * 99 / 100;
    tx.accounts.signer.lamports += caseAmountLamports * 99 / 100;
    if (expertDepositLamports > 0) {
      tx.accounts.dataAccount.lamports -= expertDepositLamports;
      tx.accounts.signer.lamports += expertDepositLamports;
    }
    status = Status.GotIncome;
  }

  @mutableSigner(signer)
  function platformCloseCase() external {
    require(status == Status.GotIncome);
    require(tx.accounts.signer.key == platformPubKey);
    tx.accounts.dataAccount.lamports -= caseAmountLamports * 1 / 100;
    tx.accounts.signer.lamports += caseAmountLamports * 1 / 100;
    status = Status.Closed;
  }
}
