-- Grant SELECT permissions to service_role for tables used in nested selects
GRANT SELECT ON taug.investment_theses TO service_role;
GRANT SELECT ON taug.research_questions TO service_role;
GRANT SELECT ON taug.portfolio_positions TO service_role;
