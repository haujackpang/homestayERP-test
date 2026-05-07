-- Management Dashboard V1 unit configuration fields.
-- Safe to run multiple times in the test Supabase SQL Editor.

alter table public.unit_config
  add column if not exists business_model text not null default 'owner_profit_sharing',
  add column if not exists monthly_rent numeric not null default 0,
  add column if not exists market_rent_baseline numeric not null default 0,
  add column if not exists market_rent_source_url text not null default '',
  add column if not exists market_rent_reviewed_at date;

alter table public.unit_config
  drop constraint if exists unit_config_business_model_check;

alter table public.unit_config
  add constraint unit_config_business_model_check
  check (
    business_model in (
      'owner_profit_sharing',
      'rented_homestay',
      'long_term_management',
      'company_office_excluded'
    )
  );

update public.unit_config
set business_model = 'company_office_excluded'
where unit_name = 'MP Office';
