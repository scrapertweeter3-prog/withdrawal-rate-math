# WithdrawalRateMath

FIRE withdrawal-rate math for Swift: whether a plan survives
sequence-of-returns risk across a long retirement, priced per scenario.

- `realWithdrawal` - the inflation-adjusted floor each year has to cover
- `portfolioAfter` - one return sequence, one ending balance
- `survivalYears` - when a sequence actually kills the plan
- `guardrailCut` - the withdrawal after a guardrail step-down
- `runwayYears` - years of current spend the remaining balance covers
- `annualSavingsFor` - savings needed to hit a target balance at a real return

All money math runs on `Decimal`, so plan audits never inherit
floating-point drift. Pure Foundation, no dependencies, iOS 13+ / macOS
10.15+, Swift 5.9.

## Why

A fixed withdrawal rule is judged on its average outcome. Retirement is
not an average: a plan that survives 49 of 50 years in every scenario
except the one you retire into is not 98% safe. This pod prices each
sequence directly so the failure points are visible, and prints the
guardrail cut and remaining runway when a portfolio crosses its floor.

## Usage

    let math = WithdrawalRateMath()
    let years = try math.survivalYears(
        startingBalance: 1_000_000,
        annualReturns: [0.05, -0.15, 0.02, 0.04],
        firstWithdrawal: 40_000,
        inflationRate: 0.03)
    // years = the index where that sequence depletes the portfolio, or 4

## Installation (CocoaPods)

    pod 'WithdrawalRateMath', '~> 0.1'

Built by the [Firenomics](https://www.firenomics.com) team, which
publishes withdrawal-rate and sequence-risk math for early retirees.

## License

MIT
