from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Iterable, TypeVar

from ..__init__ import __version__
from ..supabase_rest import (
  CanonicalSecurity,
  FinancialStatementRecord,
  FilingRecord,
  FilingVersionRecord,
  FinancialStatementItemKey,
  RawSource,
  ReportingPeriodRecord,
  SupabaseRestClient,
  UpsertResult,
)
from ..validators.sec_companyfacts import (
  ValidationFailure,
  validate_sec_companyfacts_payload,
)


ALLOWED_FORMS: frozenset[str] = frozenset({"10-K", "10-Q", "10-K/A", "10-Q/A"})
STATEMENT_TYPE_INCOME: str = "income_statement"
STATEMENT_TYPE_BALANCE: str = "balance_sheet"
STATEMENT_TYPE_CASH_FLOW: str = "cash_flow"
STATEMENT_TYPE_EQUITY: str = "equity"


@dataclass(frozen=True)
class FactMapping:
  statement_type: str
  unit_type: str | None


FACT_CATALOG: dict[str, FactMapping] = {
  # === INCOME STATEMENT ===
  # Revenue variants
  "RevenueFromContractWithCustomerExcludingAssessedTax": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "SalesRevenueNet": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "Revenues": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "SalesRevenueGoodsNet": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "SalesRevenueServicesNet": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "RevenueFromContractWithCustomerIncludingAssessedTax": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "SubscriptionRevenue": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "LicenseRevenue": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "AdvertisingRevenue": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  # Cost and gross profit
  "GrossProfit": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "CostOfGoodsAndServicesSold": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "CostOfRevenue": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "CostOfGoodsSold": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "CostOfServices": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  # Operating expenses
  "OperatingExpenses": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "OperatingIncomeLoss": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "ResearchAndDevelopmentExpense": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "SellingGeneralAndAdministrativeExpense": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "SellingAndMarketingExpense": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "GeneralAndAdministrativeExpense": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "DepreciationAndAmortization": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "AmortizationOfIntangibleAssets": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "RestructuringCharges": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "GoodwillImpairmentLoss": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "AssetImpairmentCharges": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  # Non-operating income/expense
  "InterestIncomeExpenseNonoperatingNet": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "InvestmentIncomeNet": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "InterestAndDebtExpense": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "InterestExpense": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "InterestIncome": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "OtherNonoperatingIncomeExpense": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "GainLossOnInvestments": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "ForeignCurrencyTransactionGainLossBeforeTax": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  # Tax and net income
  "IncomeTaxExpenseBenefit": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "IncomeTaxExpenseBenefitContinuingOperations": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "NetIncomeLoss": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "NetIncomeLossAttributableToNoncontrollingInterest": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "NetIncomeLossAvailableToCommonStockholdersBasic": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "ProfitLoss": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "ComprehensiveIncomeNetOfTax": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  # Per-share
  "EarningsPerShareBasic": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="ratio",
  ),
  "EarningsPerShareDiluted": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="ratio",
  ),
  "DividendsPerShare": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="ratio",
  ),
  "DividendsCommonStockCash": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "DividendsPreferredStockCash": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  # EBITDA / EBIT
  "IncomeLossFromContinuingOperationsBeforeIncomeTaxesExtraordinaryItemsNoncontrollingInterest": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "IncomeLossFromContinuingOperations": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "IncomeLossFromDiscontinuedOperationsNetOfTax": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),

  # === BALANCE SHEET ===
  # Assets
  "Assets": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "AssetsCurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "CashAndCashEquivalentsAtCarryingValue": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "CashCashEquivalentsAndShortTermInvestments": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "ShortTermInvestments": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "AccountsReceivableNetCurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "AccountsReceivableGrossCurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "InventoryNet": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "PrepaidExpenseAndOtherAssetsCurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "AssetsNoncurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "PropertyPlantAndEquipmentNet": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "Goodwill": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "IntangibleAssetsNetExcludingGoodwill": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "IntangibleAssetsNetIncludingGoodwill": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "LongTermInvestments": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "OperatingLeaseRightOfUseAsset": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "FinanceLeaseRightOfUseAsset": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "DeferredIncomeTaxAssetsNet": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "OtherAssetsNoncurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  # Liabilities
  "Liabilities": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "LiabilitiesCurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "AccountsPayableCurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "AccruedLiabilitiesCurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "DeferredRevenueCurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "DeferredRevenueNoncurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "LongTermDebtNoncurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "LongTermDebt": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "LongTermDebtAndCapitalLeaseObligations": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "ShortTermBorrowings": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "CommercialPaper": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "LiabilitiesNoncurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "DeferredIncomeTaxLiabilitiesNet": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "LongTermOperatingLeaseLiability": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "OtherLiabilitiesNoncurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "EmployeeRelatedLiabilitiesCurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "IncomeTaxesPayable": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  # Equity
  "StockholdersEquity": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "StockholdersEquityIncludingPortionAttributableToNoncontrollingInterest": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "CommonStockValue": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="monetary",
  ),
  "AdditionalPaidInCapitalCommonStock": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="monetary",
  ),
  "CommonStocksIncludingAdditionalPaidInCapital": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="monetary",
  ),
  "RetainedEarningsAccumulatedDeficit": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="monetary",
  ),
  "AccumulatedOtherComprehensiveIncomeLossNetOfTax": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="monetary",
  ),
  "OtherComprehensiveIncomeLossNetOfTax": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="monetary",
  ),
  "TreasuryStockValue": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="monetary",
  ),
  "NoncontrollingInterest": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="monetary",
  ),
  # Shares
  "WeightedAverageNumberOfSharesOutstandingBasic": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="shares",
  ),
  "WeightedAverageNumberOfDilutedSharesOutstanding": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="shares",
  ),
  "EntityCommonStockSharesOutstanding": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="shares",
  ),
  "CommonStockSharesAuthorized": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="shares",
  ),
  "CommonStockSharesIssued": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="shares",
  ),
  "CommonStockParOrStatedValuePerShare": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="ratio",
  ),

  # === CASH FLOW ===
  "NetCashProvidedByUsedInOperatingActivities": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "NetCashProvidedByUsedInInvestingActivities": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "NetCashProvidedByUsedInFinancingActivities": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "PaymentsToAcquirePropertyPlantAndEquipment": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "DepreciationDepletionAndAmortization": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "PaymentsToRepurchaseCommonStock": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "ProceedsFromIssuanceOfLongTermDebt": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "RepaymentsOfLongTermDebt": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "ProceedsFromIssuanceOfCommonStock": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "PaymentsOfDividends": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "PaymentsOfDividendsCommonStock": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "PaymentsToAcquireBusinessesNetOfCashAcquired": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "ProceedsFromDivestitureOfBusinesses": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "PaymentsToAcquireIntangibleAssets": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "PaymentsForProceedsFromOtherInvestingActivities": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "EffectOfExchangeRateOnCashAndCashEquivalents": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "CashAndCashEquivalentsPeriodIncreaseDecrease": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "ShareBasedCompensation": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "DeferredIncomeTaxExpenseBenefit": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "IncreaseDecreaseInAccountsReceivable": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "IncreaseDecreaseInInventories": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "IncreaseDecreaseInAccountsPayable": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "IncreaseDecreaseInAccruedLiabilities": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "IncreaseDecreaseInDeferredRevenue": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
}


ChunkItem = TypeVar("ChunkItem")


@dataclass(frozen=True)
class ParseCompanyfactsSummary:
  fetch_run_id: str
  processed_ciks: int
  succeeded_ciks: int
  failed_ciks: int
  created_reporting_periods: int
  replayed_reporting_periods: int
  created_statements: int
  replayed_statements: int
  created_items: int
  replayed_items: int


@dataclass(frozen=True)
class PendingStatementItem:
  financial_statement_id: str
  taxonomy_item_id: str | None
  lineage_source_id: str
  value_numeric: int | float
  unit: str
  scale: int | None
  decimals: int | None
  fact_period_start: str | None
  fact_period_end: str | None
  fact_instant: str | None
  metadata: dict[str, object]


def run_parse_sec_companyfacts(
  *,
  ciks: Iterable[str],
  supabase_client: SupabaseRestClient,
) -> ParseCompanyfactsSummary:
  normalized_ciks: list[str] = [cik.zfill(10) for cik in ciks if cik.strip()]
  if not normalized_ciks:
    raise ValueError("At least one CIK is required for parse_sec_companyfacts")

  source: RawSource = supabase_client.ensure_sec_source()
  checkpoint_scope: dict[str, object] = {
    "ciks": normalized_ciks,
    "job_type": "statement_parse",
    "record_type": "sec_companyfacts",
  }
  checkpoint_scope_key: str = supabase_client.build_checkpoint_scope_key(
    job_type="statement_parse",
    scope=checkpoint_scope,
  )
  fetch_run_id: str = supabase_client.insert_fetch_run(
    raw_source_id=source.id,
    job_type="statement_parse",
    job_scope={
      "source": source.code,
      "record_type": "sec_companyfacts",
      "cik_count": len(normalized_ciks),
      "ciks": normalized_ciks,
      "checkpoint_scope_key": checkpoint_scope_key,
    },
    worker_version=__version__,
  )

  success_count: int = 0
  failure_count: int = 0
  created_reporting_periods: int = 0
  replayed_reporting_periods: int = 0
  created_statements: int = 0
  replayed_statements: int = 0
  created_items: int = 0
  replayed_items: int = 0
  successful_cik_ids: list[str] = []
  failed_cik_ids: list[str] = []
  currencies_by_code: dict[str, str] = supabase_client.list_currencies()

  try:
    raw_records = supabase_client.list_latest_raw_records(
      record_type="sec_companyfacts",
      source_entity_keys=normalized_ciks,
      limit=max(len(normalized_ciks) * 5, 10),
    )
    raw_records_by_cik: dict[str, Any] = {
      raw_record.source_entity_key: raw_record
      for raw_record in raw_records
      if raw_record.source_entity_key is not None
    }

    for cik in normalized_ciks:
      raw_record = raw_records_by_cik.get(cik)
      if raw_record is None:
        failure_count += 1
        failed_cik_ids.append(cik)
        supabase_client.insert_validation_event(
          entity_type="sec_company",
          entity_id=cik,
          validation_rule="sec_companyfacts_raw_record_available",
          status="failed",
          message="No latest sec_companyfacts raw_record was available for parsing.",
          payload={
            "source": source.code,
            "worker_version": __version__,
            "cik": cik,
          },
        )
        continue

      try:
        payload_validation_failures: tuple[ValidationFailure, ...] = (
          validate_sec_companyfacts_payload(raw_record.payload_json)
        )
        if payload_validation_failures:
          raise ValueError(
            "SEC companyfacts payload validation failed during parse: "
            + ", ".join(failure.code for failure in payload_validation_failures)
          )

        canonical_security: CanonicalSecurity | None = (
          supabase_client.get_canonical_security_by_cik(cik=cik)
        )
        if canonical_security is None:
          entity_name: str = str(raw_record.metadata.get("entity_name") or cik)
          ticker_value: object = raw_record.metadata.get("ticker")
          ticker: str | None = ticker_value if isinstance(ticker_value, str) else None
          canonical_security = supabase_client.ensure_canonical_security(
            cik=cik,
            ticker=ticker,
            company_name=entity_name,
          )

        company_filings: list[FilingRecord] = supabase_client.list_filings_for_company(
          company_id=canonical_security.company_id,
          raw_source_id=source.id,
          limit=500,
        )
        existing_reporting_periods = supabase_client.list_reporting_periods_for_company(
          company_id=canonical_security.company_id,
          limit=5000,
        )
        filings_by_key: dict[str, FilingRecord] = {
          filing.filing_key: filing for filing in company_filings
        }
        active_versions_by_filing_id: dict[str, FilingVersionRecord] = {
          filing_version.filing_id: filing_version
          for filing_version in supabase_client.list_active_filing_versions_for_filings(
            filing_ids=[filing.id for filing in company_filings],
            limit=max(len(company_filings) * 4, 1000),
          )
        }
        relevant_filing_version_ids: list[str] = list(
          {
            filing_version_id
            for filing_version in active_versions_by_filing_id.values()
            for filing_version_id in (
              filing_version.id,
              filing_version.supersedes_filing_version_id,
            )
            if filing_version_id is not None
          }
        )
        existing_statements = supabase_client.list_financial_statements_for_filing_versions(
          filing_version_ids=relevant_filing_version_ids,
          limit=10000,
        )

        parse_counts = _parse_companyfacts_record(
          raw_record_id=raw_record.id,
          cik=cik,
          payload=raw_record.payload_json,
          company_id=canonical_security.company_id,
          security_id=canonical_security.security_id,
          filings_by_key=filings_by_key,
          active_versions_by_filing_id=active_versions_by_filing_id,
          existing_reporting_periods=existing_reporting_periods,
          existing_statements=existing_statements,
          currencies_by_code=currencies_by_code,
          supabase_client=supabase_client,
        )
        created_reporting_periods += parse_counts["created_reporting_periods"]
        replayed_reporting_periods += parse_counts["replayed_reporting_periods"]
        created_statements += parse_counts["created_statements"]
        replayed_statements += parse_counts["replayed_statements"]
        created_items += parse_counts["created_items"]
        replayed_items += parse_counts["replayed_items"]

        supabase_client.insert_validation_event(
          entity_type="raw_record",
          entity_id=raw_record.id,
          validation_rule="sec_companyfacts_statement_parse",
          status="passed",
          message="SEC companyfacts raw_record parsed into statement-layer rows.",
          payload={
            "source": source.code,
            "worker_version": __version__,
            "cik": cik,
            **parse_counts,
          },
        )
        supabase_client.insert_audit_event(
          event_type="sec_companyfacts_statement_parsed",
          entity_type="raw_record",
          entity_id=raw_record.id,
          severity="info",
          reference_type="raw_fetch_run",
          reference_id=fetch_run_id,
          payload={
            "source": source.code,
            "worker_version": __version__,
            "cik": cik,
            "company_id": canonical_security.company_id,
            "security_id": canonical_security.security_id,
            **parse_counts,
          },
        )
        success_count += 1
        successful_cik_ids.append(cik)
      except Exception as exc:
        failure_count += 1
        failed_cik_ids.append(cik)
        supabase_client.insert_validation_event(
          entity_type="sec_company",
          entity_id=cik,
          validation_rule="sec_companyfacts_statement_parse",
          status="failed",
          message=str(exc),
          payload={
            "source": source.code,
            "worker_version": __version__,
            "cik": cik,
            "raw_record_id": raw_record.id,
            "error_type": type(exc).__name__,
          },
        )
        supabase_client.insert_audit_event(
          event_type="sec_companyfacts_statement_parse_failed",
          entity_type="sec_company",
          entity_id=cik,
          severity="error",
          reference_type="raw_fetch_run",
          reference_id=fetch_run_id,
          payload={
            "source": source.code,
            "worker_version": __version__,
            "cik": cik,
            "raw_record_id": raw_record.id,
            "error_type": type(exc).__name__,
            "error_message": str(exc),
          },
        )
        continue

    run_status: str = "success"
    error_code: str | None = None
    error_message: str | None = None
    if success_count == 0:
      run_status = "failed"
      error_code = "sec_companyfacts_statement_parse_failed"
      error_message = "All requested CIKs failed during SEC companyfacts statement parsing."
    elif failure_count > 0:
      run_status = "partial"
      error_code = "sec_companyfacts_statement_parse_partial_failure"
      error_message = "One or more requested CIKs failed during SEC companyfacts statement parsing."

    supabase_client.update_fetch_run(
      fetch_run_id=fetch_run_id,
      status=run_status,
      error_code=error_code,
      error_message=error_message,
      metadata={
        "successful_cik_ids": successful_cik_ids,
        "failed_cik_ids": failed_cik_ids,
        "created_reporting_periods": created_reporting_periods,
        "replayed_reporting_periods": replayed_reporting_periods,
        "created_statements": created_statements,
        "replayed_statements": replayed_statements,
        "created_items": created_items,
        "replayed_items": replayed_items,
      },
    )
    if success_count > 0:
      supabase_client.upsert_ingestion_checkpoint(
        raw_source_id=source.id,
        job_type="statement_parse",
        checkpoint_scope_key=checkpoint_scope_key,
        last_success_fetch_run_id=fetch_run_id,
        checkpoint_data={
          "successful_cik_ids": successful_cik_ids,
          "failed_cik_ids": failed_cik_ids,
          "created_reporting_periods": created_reporting_periods,
          "replayed_reporting_periods": replayed_reporting_periods,
          "created_statements": created_statements,
          "replayed_statements": replayed_statements,
          "created_items": created_items,
          "replayed_items": replayed_items,
        },
      )

    return ParseCompanyfactsSummary(
      fetch_run_id=fetch_run_id,
      processed_ciks=len(normalized_ciks),
      succeeded_ciks=success_count,
      failed_ciks=failure_count,
      created_reporting_periods=created_reporting_periods,
      replayed_reporting_periods=replayed_reporting_periods,
      created_statements=created_statements,
      replayed_statements=replayed_statements,
      created_items=created_items,
      replayed_items=replayed_items,
    )
  except Exception as exc:
    supabase_client.update_fetch_run(
      fetch_run_id=fetch_run_id,
      status="failed",
      error_code="sec_companyfacts_statement_parse_failed",
      error_message=str(exc),
      metadata={
        "successful_cik_ids": successful_cik_ids,
        "failed_cik_ids": failed_cik_ids,
        "created_reporting_periods": created_reporting_periods,
        "replayed_reporting_periods": replayed_reporting_periods,
        "created_statements": created_statements,
        "replayed_statements": replayed_statements,
        "created_items": created_items,
        "replayed_items": replayed_items,
      },
    )
    raise


def _parse_companyfacts_record(
  *,
  raw_record_id: str,
  cik: str,
  payload: dict[str, object],
  company_id: str,
  security_id: str,
  filings_by_key: dict[str, FilingRecord],
  active_versions_by_filing_id: dict[str, FilingVersionRecord],
  existing_reporting_periods: list[ReportingPeriodRecord],
  existing_statements: list[FinancialStatementRecord],
  currencies_by_code: dict[str, str],
  supabase_client: SupabaseRestClient,
) -> dict[str, int]:
  counts: dict[str, int] = {
    "created_reporting_periods": 0,
    "replayed_reporting_periods": 0,
    "created_statements": 0,
    "replayed_statements": 0,
    "created_items": 0,
    "replayed_items": 0,
    "matched_filings": 0,
    "skipped_entries": 0,
    "linked_restatement_statements": 0,
  }
  reporting_period_cache: dict[str, str] = {}
  statement_cache: dict[str, str] = {}
  taxonomy_cache: dict[str, str] = {}
  matched_filing_ids: set[str] = set()
  pending_items: list[PendingStatementItem] = []
  preloaded_reporting_period_keys: set[str] = set()
  for record in existing_reporting_periods:
    cache_key: str = _reporting_period_cache_key(
      period_type=record.period_type,
      fiscal_year=record.fiscal_year,
      fiscal_quarter=record.fiscal_quarter,
      period_end=record.period_end,
    )
    reporting_period_cache[cache_key] = record.id
    preloaded_reporting_period_keys.add(cache_key)
  preloaded_statement_keys: set[str] = set()
  statement_records_by_key: dict[str, FinancialStatementRecord] = {}
  statement_records_by_id: dict[str, FinancialStatementRecord] = {}
  for record in existing_statements:
    if record.statement_version != 1:
      continue
    cache_key = _statement_cache_key(
      filing_version_id=record.filing_version_id,
      statement_type=record.statement_type,
      period_end=record.period_end,
    )
    statement_cache[cache_key] = record.id
    preloaded_statement_keys.add(cache_key)
    statement_records_by_key[cache_key] = record
    statement_records_by_id[record.id] = record
  counted_replayed_reporting_period_keys: set[str] = set()
  counted_replayed_statement_keys: set[str] = set()

  facts_value: object = payload.get("facts")
  if not isinstance(facts_value, dict):
    return counts

  for taxonomy_source, taxonomy_value in facts_value.items():
    if not isinstance(taxonomy_source, str) or not isinstance(taxonomy_value, dict):
      continue
    for concept_code, concept_payload in taxonomy_value.items():
      mapping: FactMapping | None = FACT_CATALOG.get(concept_code)
      if mapping is None:
        continue
      if not isinstance(concept_payload, dict):
        continue
      label_value: object = concept_payload.get("label")
      concept_label: str = (
        label_value.strip()
        if isinstance(label_value, str) and label_value.strip()
        else concept_code
      )
      taxonomy_key: str = f"{taxonomy_source}:{concept_code}"
      taxonomy_item_id: str | None = taxonomy_cache.get(taxonomy_key)
      if taxonomy_item_id is None:
        taxonomy_result: UpsertResult = supabase_client.upsert_statement_taxonomy_item(
          code=concept_code,
          name=concept_label,
          statement_type=mapping.statement_type,
          unit_type=mapping.unit_type,
          sign_convention="natural",
          taxonomy_source=taxonomy_source,
          is_core=True,
          metadata={
            "source": "sec_edgar",
            "parser": "sec_companyfacts",
            "cik": cik,
          },
        )
        taxonomy_item_id = taxonomy_result.id
        taxonomy_cache[taxonomy_key] = taxonomy_item_id

      units_value: object = concept_payload.get("units")
      if not isinstance(units_value, dict):
        continue
      for unit_name, fact_entries in units_value.items():
        if not isinstance(unit_name, str) or not isinstance(fact_entries, list):
          continue
        currency_id: str | None = _resolve_currency_id(
          unit=unit_name,
          currencies_by_code=currencies_by_code,
        )
        for entry in fact_entries:
          if not isinstance(entry, dict):
            counts["skipped_entries"] += 1
            continue
          parsed_entry = _parse_fact_entry(entry)
          if parsed_entry is None:
            counts["skipped_entries"] += 1
            continue
          accession_number: str = parsed_entry["accession_number"]
          filing_record: FilingRecord | None = filings_by_key.get(accession_number)
          if filing_record is None:
            counts["skipped_entries"] += 1
            continue
          active_version: FilingVersionRecord | None = active_versions_by_filing_id.get(
            filing_record.id
          )
          if active_version is None:
            counts["skipped_entries"] += 1
            continue
          matched_filing_ids.add(filing_record.id)

          reporting_period_cache_key: str = _reporting_period_cache_key(
            period_type=parsed_entry["period_type"],
            fiscal_year=parsed_entry["fiscal_year"],
            fiscal_quarter=parsed_entry["fiscal_quarter"],
            period_end=parsed_entry["period_end"],
          )
          reporting_period_id: str | None = reporting_period_cache.get(
            reporting_period_cache_key
          )
          if reporting_period_id is None:
            reporting_period_result: UpsertResult = supabase_client.upsert_reporting_period(
              company_id=company_id,
              period_type=parsed_entry["period_type"],
              fiscal_year=parsed_entry["fiscal_year"],
              fiscal_quarter=parsed_entry["fiscal_quarter"],
              period_start=parsed_entry["period_start"],
              period_end=parsed_entry["period_end"],
              label=parsed_entry["label"],
              last_reported_at=parsed_entry["filed_at"],
              last_fetched_at=_iso_now(),
              last_verified_at=_iso_now(),
              metadata={
                "source": "sec_edgar",
                "parser": "sec_companyfacts",
                "form": parsed_entry["form"],
                "accession_number": accession_number,
              },
            )
            reporting_period_id = reporting_period_result.id
            reporting_period_cache[reporting_period_cache_key] = reporting_period_id
            counts[
              "created_reporting_periods"
              if reporting_period_result.created
              else "replayed_reporting_periods"
            ] += 1
          elif (
            reporting_period_cache_key in preloaded_reporting_period_keys
            and reporting_period_cache_key not in counted_replayed_reporting_period_keys
          ):
            counted_replayed_reporting_period_keys.add(reporting_period_cache_key)
            counts["replayed_reporting_periods"] += 1

          statement_cache_key: str = _statement_cache_key(
            filing_version_id=active_version.id,
            statement_type=mapping.statement_type,
            period_end=parsed_entry["period_end"],
          )
          financial_statement_id: str | None = statement_cache.get(statement_cache_key)
          if financial_statement_id is None:
            statement_result: UpsertResult = supabase_client.upsert_financial_statement(
              company_id=company_id,
              security_id=security_id,
              filing_id=filing_record.id,
              filing_version_id=active_version.id,
              reporting_period_id=reporting_period_id,
              statement_type=mapping.statement_type,
              statement_version=1,
              currency_id=currency_id,
              period_start=parsed_entry["period_start"],
              period_end=parsed_entry["period_end"],
              published_at=parsed_entry["filed_at"],
              is_restated=filing_record.is_amendment,
              last_reported_at=parsed_entry["filed_at"],
              last_fetched_at=_iso_now(),
              last_verified_at=_iso_now(),
              parser_version=__version__,
              status="active",
              metadata={
                "source": "sec_edgar",
                "parser": "sec_companyfacts",
                "form": parsed_entry["form"],
                "accession_number": accession_number,
              },
            )
            financial_statement_id = statement_result.id
            statement_cache[statement_cache_key] = financial_statement_id
            current_statement_record = FinancialStatementRecord(
              id=financial_statement_id,
              filing_version_id=active_version.id,
              statement_type=mapping.statement_type,
              period_end=parsed_entry["period_end"],
              statement_version=1,
              is_restated=filing_record.is_amendment,
              supersedes_statement_id=None,
              superseded_by_statement_id=None,
              status="active",
            )
            statement_records_by_key[statement_cache_key] = current_statement_record
            statement_records_by_id[financial_statement_id] = current_statement_record
            counts[
              "created_statements"
              if statement_result.created
              else "replayed_statements"
            ] += 1
          elif (
            statement_cache_key in preloaded_statement_keys
            and statement_cache_key not in counted_replayed_statement_keys
          ):
            counted_replayed_statement_keys.add(statement_cache_key)
            counts["replayed_statements"] += 1
          current_statement_record = statement_records_by_key.get(statement_cache_key)
          if current_statement_record is None and financial_statement_id is not None:
            current_statement_record = statement_records_by_id.get(financial_statement_id)
          if current_statement_record is not None:
            linked_statement_record = _maybe_link_statement_restatement(
              filing_record=filing_record,
              current_filing_version=active_version,
              current_statement=current_statement_record,
              statement_records_by_key=statement_records_by_key,
              statement_records_by_id=statement_records_by_id,
              supabase_client=supabase_client,
            )
            if linked_statement_record is not None:
              statement_records_by_key[statement_cache_key] = linked_statement_record
              statement_records_by_id[linked_statement_record.id] = linked_statement_record
              counts["linked_restatement_statements"] += 1

          lineage_source_id: str = "|".join(
            (
              raw_record_id,
              taxonomy_source,
              concept_code,
              unit_name,
              accession_number,
              parsed_entry["filed"],
              parsed_entry["period_start"] or "",
              parsed_entry["period_end"],
              parsed_entry["fp"] or "",
            )
          )
          pending_items.append(
            PendingStatementItem(
              financial_statement_id=financial_statement_id,
              taxonomy_item_id=taxonomy_item_id,
              lineage_source_id=lineage_source_id,
              value_numeric=parsed_entry["value_numeric"],
              unit=unit_name,
              scale=_parse_optional_int(entry.get("scale")),
              decimals=_parse_optional_int(entry.get("decimals")),
              fact_period_start=parsed_entry["period_start"],
              fact_period_end=(
                parsed_entry["period_end"]
                if parsed_entry["period_type"] != "instant"
                else None
              ),
              fact_instant=(
                parsed_entry["period_end"]
                if parsed_entry["period_type"] == "instant"
                else None
              ),
              metadata={
                "source": "sec_edgar",
                "parser": "sec_companyfacts",
                "form": parsed_entry["form"],
                "accession_number": accession_number,
                "filed": parsed_entry["filed"],
              },
            )
          )

  counts["matched_filings"] = len(matched_filing_ids)
  _flush_pending_statement_items(
    pending_items=pending_items,
    supabase_client=supabase_client,
    counts=counts,
  )
  return counts


def _flush_pending_statement_items(
  *,
  pending_items: list[PendingStatementItem],
  supabase_client: SupabaseRestClient,
  counts: dict[str, int],
) -> None:
  if not pending_items:
    return

  statement_ids: list[str] = sorted(
    {
      pending_item.financial_statement_id
      for pending_item in pending_items
    }
  )
  existing_keys: set[FinancialStatementItemKey] = set()
  for statement_id_chunk in _chunked(statement_ids, 100):
    existing_keys.update(
      supabase_client.list_financial_statement_item_keys(
        financial_statement_ids=statement_id_chunk,
        limit=20000,
      )
    )

  local_keys: set[FinancialStatementItemKey] = set()
  rows_to_insert: list[dict[str, object]] = []
  replayed_items: int = 0
  created_items: int = 0
  for pending_item in pending_items:
    item_key = FinancialStatementItemKey(
      financial_statement_id=pending_item.financial_statement_id,
      lineage_source_type="xbrl_fact",
      lineage_source_id=pending_item.lineage_source_id,
    )
    if item_key in existing_keys or item_key in local_keys:
      replayed_items += 1
      continue
    local_keys.add(item_key)
    created_items += 1
    rows_to_insert.append(
      {
        "financial_statement_id": pending_item.financial_statement_id,
        "taxonomy_item_id": pending_item.taxonomy_item_id,
        "lineage_source_type": "xbrl_fact",
        "lineage_source_id": pending_item.lineage_source_id,
        "value_numeric": pending_item.value_numeric,
        "value_text": None,
        "unit": pending_item.unit,
        "scale": pending_item.scale,
        "decimals": pending_item.decimals,
        "fact_period_start": pending_item.fact_period_start,
        "fact_period_end": pending_item.fact_period_end,
        "fact_instant": pending_item.fact_instant,
        "is_reported": True,
        "is_calculated": False,
        "confidence_score": 1.0,
        "metadata": pending_item.metadata,
      }
    )

  for row_chunk in _chunked(rows_to_insert, 500):
    supabase_client.bulk_insert_financial_statement_items(rows=row_chunk)

  counts["created_items"] += created_items
  counts["replayed_items"] += replayed_items


def _maybe_link_statement_restatement(
  *,
  filing_record: FilingRecord,
  current_filing_version: FilingVersionRecord,
  current_statement: FinancialStatementRecord,
  statement_records_by_key: dict[str, FinancialStatementRecord],
  statement_records_by_id: dict[str, FinancialStatementRecord],
  supabase_client: SupabaseRestClient,
) -> FinancialStatementRecord | None:
  prior_filing_version_id: str | None = current_filing_version.supersedes_filing_version_id
  if not filing_record.is_amendment or prior_filing_version_id is None:
    return None
  if current_statement.supersedes_statement_id is not None:
    return None

  prior_statement_key: str = _statement_cache_key(
    filing_version_id=prior_filing_version_id,
    statement_type=current_statement.statement_type,
    period_end=current_statement.period_end,
  )
  prior_statement: FinancialStatementRecord | None = statement_records_by_key.get(
    prior_statement_key
  )
  if prior_statement is None:
    return None
  if prior_statement.id == current_statement.id:
    return None

  supabase_client.update_financial_statement_supersession(
    financial_statement_id=current_statement.id,
    supersedes_statement_id=prior_statement.id,
    is_restated=True,
    status="active",
  )
  supabase_client.update_financial_statement_supersession(
    financial_statement_id=prior_statement.id,
    superseded_by_statement_id=current_statement.id,
    status="superseded",
  )
  supabase_client.insert_restatement_event(
    entity_type="financial_statement",
    entity_id=current_statement.id,
    prior_reference_id=prior_statement.id,
    new_reference_id=current_statement.id,
    detection_method="sec_amendment_statement_lineage",
    status="validated",
    payload={
      "source": "sec_edgar",
      "statement_type": current_statement.statement_type,
      "period_end": current_statement.period_end,
      "current_filing_version_id": current_filing_version.id,
      "prior_filing_version_id": prior_filing_version_id,
      "current_statement_id": current_statement.id,
      "prior_statement_id": prior_statement.id,
    },
  )
  supabase_client.insert_audit_event(
    event_type="financial_statement_restatement_linked",
    entity_type="financial_statement",
    entity_id=current_statement.id,
    severity="info",
    payload={
      "source": "sec_edgar",
      "statement_type": current_statement.statement_type,
      "period_end": current_statement.period_end,
      "current_filing_version_id": current_filing_version.id,
      "prior_filing_version_id": prior_filing_version_id,
      "prior_statement_id": prior_statement.id,
    },
  )

  updated_current = FinancialStatementRecord(
    id=current_statement.id,
    filing_version_id=current_statement.filing_version_id,
    statement_type=current_statement.statement_type,
    period_end=current_statement.period_end,
    statement_version=current_statement.statement_version,
    is_restated=True,
    supersedes_statement_id=prior_statement.id,
    superseded_by_statement_id=current_statement.superseded_by_statement_id,
    status="active",
  )
  updated_prior = FinancialStatementRecord(
    id=prior_statement.id,
    filing_version_id=prior_statement.filing_version_id,
    statement_type=prior_statement.statement_type,
    period_end=prior_statement.period_end,
    statement_version=prior_statement.statement_version,
    is_restated=prior_statement.is_restated,
    supersedes_statement_id=prior_statement.supersedes_statement_id,
    superseded_by_statement_id=current_statement.id,
    status="superseded",
  )
  statement_records_by_key[prior_statement_key] = updated_prior
  statement_records_by_id[prior_statement.id] = updated_prior
  return updated_current


def _parse_fact_entry(entry: dict[str, Any]) -> dict[str, Any] | None:
  form_value: object = entry.get("form")
  accession_value: object = entry.get("accn")
  end_value: object = entry.get("end")
  filed_value: object = entry.get("filed")
  value: object = entry.get("val")
  fiscal_year_value: object = entry.get("fy")
  fp_value: object = entry.get("fp")

  if (
    not isinstance(form_value, str)
    or form_value not in ALLOWED_FORMS
    or not isinstance(accession_value, str)
    or not isinstance(end_value, str)
    or not isinstance(filed_value, str)
    or not isinstance(fiscal_year_value, int)
    or not isinstance(value, (int, float))
  ):
    return None

  fp: str | None = fp_value if isinstance(fp_value, str) and fp_value.strip() else None
  period_start_value: object = entry.get("start")
  period_start: str | None = (
    period_start_value if isinstance(period_start_value, str) and period_start_value else None
  )
  period_type: str = _derive_period_type(form=form_value, fp=fp, period_start=period_start)
  fiscal_quarter: int | None = _derive_fiscal_quarter(fp=fp, period_type=period_type)
  label: str = _build_period_label(
    period_type=period_type,
    fiscal_year=fiscal_year_value,
    fiscal_quarter=fiscal_quarter,
    period_end=end_value,
  )

  return {
    "form": form_value,
    "accession_number": accession_value,
    "period_end": end_value,
    "period_start": period_start,
    "filed": filed_value,
    "filed_at": _date_to_timestamp(filed_value),
    "value_numeric": value,
    "fiscal_year": fiscal_year_value,
    "fiscal_quarter": fiscal_quarter,
    "period_type": period_type,
    "label": label,
    "fp": fp,
  }


def _derive_period_type(*, form: str, fp: str | None, period_start: str | None) -> str:
  if period_start is None:
    return "instant"
  if fp == "FY" or form in {"10-K", "10-K/A"}:
    return "annual"
  if fp in {"Q1", "Q2", "Q3"} or form in {"10-Q", "10-Q/A"}:
    return "quarterly"
  return "annual"


def _derive_fiscal_quarter(*, fp: str | None, period_type: str) -> int | None:
  if period_type != "quarterly":
    return None
  quarter_map: dict[str, int] = {"Q1": 1, "Q2": 2, "Q3": 3, "Q4": 4}
  if fp is None:
    return None
  return quarter_map.get(fp)


def _build_period_label(
  *,
  period_type: str,
  fiscal_year: int,
  fiscal_quarter: int | None,
  period_end: str,
) -> str:
  if period_type == "quarterly" and fiscal_quarter is not None:
    return f"Q{fiscal_quarter} FY{fiscal_year}"
  if period_type == "annual":
    return f"FY{fiscal_year}"
  return f"Instant {period_end}"


def _resolve_currency_id(
  *,
  unit: str,
  currencies_by_code: dict[str, str],
) -> str | None:
  unit_prefix: str = unit.split("/", 1)[0].upper()
  return currencies_by_code.get(unit_prefix)


def _reporting_period_cache_key(
  *,
  period_type: str,
  fiscal_year: int,
  fiscal_quarter: int | None,
  period_end: str,
) -> str:
  return f"{period_type}|{fiscal_year}|{fiscal_quarter}|{period_end}"


def _statement_cache_key(
  *,
  filing_version_id: str,
  statement_type: str,
  period_end: str,
) -> str:
  return f"{filing_version_id}|{statement_type}|{period_end}"


def _parse_optional_int(value: object) -> int | None:
  if isinstance(value, int):
    return value
  if isinstance(value, str) and value.lstrip("-").isdigit():
    return int(value)
  return None


def _date_to_timestamp(value: str) -> str:
  return f"{value}T00:00:00+00:00"


def _iso_now() -> str:
  return datetime.now(timezone.utc).isoformat()


def _chunked(items: list[ChunkItem], chunk_size: int) -> list[list[ChunkItem]]:
  if chunk_size <= 0:
    raise ValueError("chunk_size must be positive")
  return [
    items[index : index + chunk_size]
    for index in range(0, len(items), chunk_size)
  ]
