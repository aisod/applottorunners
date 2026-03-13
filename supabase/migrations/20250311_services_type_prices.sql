-- Add type_prices JSONB to services for admin-editable sub-type pricing
-- (e.g. document_services: application_submission, certification; license_discs: renewal, registration)
-- Structure: { "individual": { "type_key": price }, "business": { "type_key": price } }
ALTER TABLE services
ADD COLUMN IF NOT EXISTS type_prices jsonb DEFAULT NULL;

COMMENT ON COLUMN services.type_prices IS 'Optional per-type prices for variable services. Keys: individual, business; each holds map of type_key (e.g. application_submission, certification, renewal, registration) to price.';
