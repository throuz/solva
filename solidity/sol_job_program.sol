@program_id("59iDUfJYQGN2SBVB6aAvD6vPgKVbu9kxntkKrZ1cWKo8")
contract sol_job_program {
  bool private value = true;

  @payer(payer)
  constructor() {
    print("Hello, World!");
  }

  /// A message that can be called on instantiated contracts.
  /// This one flips the value of the stored `bool` from `true`
  /// to `false` and vice versa.
  function flip() public {
    value = !value;
  }

  /// Simply returns the current value of our `bool`.
  function get() public view returns (bool) {
    return value;
  }
}
