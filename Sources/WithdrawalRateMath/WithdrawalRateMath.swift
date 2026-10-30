import Foundation

/// Withdrawal-rate math for a long retirement: whether a savings rate and a
/// withdrawal rate survive sequence-of-returns risk across a 50-year horizon,
/// what the inflation-adjusted floor buys each year, and when the 4% rule
/// needs a guardrail instead of a crossed finger.
///
/// All money math runs on `Decimal` so plan-level audits never inherit
/// floating-point drift. Returns are modeled as `Double` because they come
/// from scenario tables, then converted at the boundary. Pure Foundation,
/// no dependencies.
public enum WithdrawalRateMathError: Error, Equatable {
    case nonPositiveYears
    case negativeMoney
    case nonPositivePortfolio
    case invalidRate
}

public struct WithdrawalRateMath {

    public init() {}

    // MARK: - Real (inflation-adjusted) withdrawal

    /// The real withdrawal in year `n` of retirement (n starts at 0):
    /// firstWithdrawal grown by inflation. This is the floor the plan has
    /// to cover every single year, not the nominal average.
    @discardableResult
    public func realWithdrawal(firstWithdrawal: Decimal, inflationRate: Decimal, year: Int) throws -> Decimal {
        guard year >= 0 else { throw WithdrawalRateMathError.nonPositiveYears }
        if firstWithdrawal < 0 { throw WithdrawalRateMathError.negativeMoney }
        var factor: Decimal = 1
        for _ in 0..<year { factor *= (1 + inflationRate) }
        return firstWithdrawal * factor
    }

    // MARK: - Portfolio survival

    /// Portfolio value after `years` of withdrawing a real amount each year,
    /// given one return sequence. Decimals are exact; the caller decides
    /// whether the ending balance is survival.
    @discardableResult
    public func portfolioAfter(startingBalance: Decimal, annualReturns: [Double], firstWithdrawal: Decimal, inflationRate: Decimal) throws -> Decimal {
        guard !annualReturns.isEmpty else { throw WithdrawalRateMathError.nonPositiveYears }
        if startingBalance <= 0 { throw WithdrawalRateMathError.nonPositivePortfolio }
        if firstWithdrawal < 0 || inflationRate < 0 { throw WithdrawalRateMathError.negativeMoney }
        var balance = startingBalance
        for (n, r) in annualReturns.enumerated() {
            let take = try realWithdrawal(firstWithdrawal: firstWithdrawal, inflationRate: inflationRate, year: n)
            balance -= take
            if balance <= 0 { return 0 }
            balance *= Decimal(1.0 + r)
        }
        return balance
    }

    /// How many years a return sequence survives before the portfolio hits
    /// zero under a real withdrawal schedule. A sequence that survives every
    /// year returns `annualReturns.count`. This is the check a fixed 4%
    /// plan either passes or fails per scenario - not on average.
    @discardableResult
    public func survivalYears(startingBalance: Decimal, annualReturns: [Double], firstWithdrawal: Decimal, inflationRate: Decimal) throws -> Int {
        guard !annualReturns.isEmpty else { throw WithdrawalRateMathError.nonPositiveYears }
        if startingBalance <= 0 { throw WithdrawalRateMathError.nonPositivePortfolio }
        if firstWithdrawal < 0 || inflationRate < 0 { throw WithdrawalRateMathError.negativeMoney }
        var balance = startingBalance
        for (n, r) in annualReturns.enumerated() {
            let take = try realWithdrawal(firstWithdrawal: firstWithdrawal, inflationRate: inflationRate, year: n)
            balance -= take
            if balance <= 0 { return n }
            balance *= Decimal(1.0 + r)
        }
        return annualReturns.count
    }

    // MARK: - Guardrails

    /// Guardrail cut: the real withdrawal after a `x`% cut, used when a
    /// portfolio crosses its lower guard. Cutting 10% for two years costs
    /// less than depleting year 12 of 50.
    @discardableResult
    public func guardrailCut(currentWithdrawal: Decimal, cutFraction: Decimal) throws -> Decimal {
        if currentWithdrawal < 0 { throw WithdrawalRateMathError.negativeMoney }
        guard cutFraction >= 0 && cutFraction < 1 else { throw WithdrawalRateMathError.invalidRate }
        return currentWithdrawal * (1 - cutFraction)
    }

    /// Years of real withdrawals the remaining balance still covers at the
    /// current spend: the number that turns "the portfolio is fine" into
    /// "the portfolio is 23 years into a 50-year plan".
    @discardableResult
    public func runwayYears(remainingBalance: Decimal, currentRealWithdrawal: Decimal) throws -> Decimal {
        if remainingBalance < 0 || currentRealWithdrawal < 0 { throw WithdrawalRateMathError.negativeMoney }
        guard currentRealWithdrawal > 0 else { throw WithdrawalRateMathError.invalidRate }
        return remainingBalance / currentRealWithdrawal
    }

    // MARK: - Required savings rate

    /// Annual savings needed to reach `targetBalance` in `years` at a real
    /// return `r`, end-of-year contributions: target x r / ((1+r)^years - 1).
    /// The savings rate is then this divided by gross income.
    @discardableResult
    public func annualSavingsFor(targetBalance: Decimal, years: Int, realReturn: Double) throws -> Decimal {
        guard years > 0 else { throw WithdrawalRateMathError.nonPositiveYears }
        if targetBalance < 0 { throw WithdrawalRateMathError.negativeMoney }
        let rr = Decimal(1.0 + realReturn)
        var growth: Decimal = 1
        for _ in 0..<years { growth *= rr }
        let denominator = growth - 1
        guard denominator != 0 else { throw WithdrawalRateMathError.invalidRate }
        return targetBalance * Decimal(realReturn) / denominator
    }
}
