GRANT SELECT ON taug.exchanges TO authenticated;
GRANT SELECT ON taug.exchanges TO service_role;

GRANT SELECT ON taug.symbols TO authenticated;
GRANT SELECT, INSERT, UPDATE ON taug.symbols TO service_role;
