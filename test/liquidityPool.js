const UnderlyingToken = artifacts.require("UnderlyingToken.sol");
const GovernanceToken = artifacts.require("GovernanceToken.sol");
const LiquidityPool = artifacts.require("LiquidityPool.sol");

const { time } = require("@openzeppelin/test-helpers");

contract("liquidity pool", (accounts) => {
  const [admin, trader1, trader2] = accounts;
  let underlyingToken, governanceToken, liquidityPool;

  beforeEach(async () => {
    underlyingToken = await UnderlyingToken.new();
    governanceToken = await GovernanceToken.new();
    liquidityPool = await LiquidityPool.new(underlyingToken.address, governanceToken.address);

    await governanceToken.transferOwnership(liquidityPool.address);
    await Promise.all([
      underlyingToken.faucet(trader1, web3.utils.toWei("1000")),
      underlyingToken.faucet(trader2, web3.utils.toWei("1000")),
    ]);
  });

  it("should mint 4000 gov tokens", async () => {
    const amount = web3.utils.toWei("100");
    await underlyingToken.approve(liquidityPool.address, amount, { from: trader1 });
    await liquidityPool.deposit(amount, { from: trader1 });
    await time.advanceBlock();
    await time.advanceBlock();
    await time.advanceBlock();
    await liquidityPool.withdraw(amount, { from: trader1 });
    let govToken = await governanceToken.balanceOf(trader1);
    govToken = web3.utils.fromWei(govToken);
    assert(govToken.toString(), "4000");
  });

  it("should mint 6000 gov tokens", async () => {
    const amountDeposit = web3.utils.toWei("100");
    await underlyingToken.approve(liquidityPool.address, amountDeposit, { from: trader2 });
    await liquidityPool.deposit(amountDeposit, { from: trader2 });
    await time.advanceBlock();
    await time.advanceBlock();
    await time.advanceBlock();
    await time.advanceBlock();
    await underlyingToken.approve(liquidityPool.address, amountDeposit, { from: trader2 }); // this also add 1 block in local test network
    await liquidityPool.withdraw(amountDeposit, { from: trader2 });
    let govToken = await governanceToken.balanceOf(trader2);
    govToken = web3.utils.fromWei(govToken);
    assert.equal(govToken, 6000);
  });
});
