const UnderlyingToken = artifacts.require("UnderlyingToken.sol");
const GovernanceToken = artifacts.require("GovernanceToken.sol");
const LiquidityPool2 = artifacts.require("LiquidityPool2.sol");

const { time } = require("@openzeppelin/test-helpers");

contract("liquidity pool2", (accounts) => {
  const [admin, trader1, trader2] = accounts;
  let underlyingToken, governanceToken, liquidityPool2;

  beforeEach(async () => {
    underlyingToken = await UnderlyingToken.new();
    governanceToken = await GovernanceToken.new();
    liquidityPool2 = await LiquidityPool2.new(underlyingToken.address, governanceToken.address);

    await governanceToken.transferOwnership(liquidityPool2.address);
    await Promise.all([
      underlyingToken.faucet(trader1, web3.utils.toWei("1000")),
      underlyingToken.faucet(trader2, web3.utils.toWei("1000")),
    ]);
  });

  it("should mint 4000 gov tokens", async () => {
    const amount = web3.utils.toWei("100");
    await underlyingToken.approve(liquidityPool2.address, amount + amount + amount, { from: trader1 });
    await liquidityPool2.deposit(amount, { from: trader1 });
    await liquidityPool2.deposit(amount, { from: trader1 });
    await liquidityPool2.deposit(amount, { from: trader1 });
    const avg = await liquidityPool2._getAverageTotalBalance();
    await time.advanceBlock();
    await time.advanceBlock();
    await time.advanceBlock();
    await liquidityPool2.withdraw(amount, { from: trader1 });
    let govToken = await governanceToken.balanceOf(trader1);
    assert(govToken.toString(), "4000");
  });
});
