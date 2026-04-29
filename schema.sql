-- Franz Plumbing & Piping, Inc. — Supabase Schema
-- All tables prefixed fp_ to avoid collision with other projects on this Supabase instance
-- Run this once in Supabase SQL Editor

-- Users
create table if not exists fp_users (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text unique not null,
  password_hash text not null,
  role text not null default 'tech', -- 'admin' | 'tech'
  phone text,
  active boolean default true,
  created_at timestamptz default now()
);

-- Customers
create table if not exists fp_customers (
  id uuid primary key default gen_random_uuid(),
  first_name text not null,
  last_name text not null,
  company text,
  phone text,
  email text,
  address text,
  city text,
  state text default 'WI',
  zip text,
  notes text,
  created_at timestamptz default now()
);

-- Pricebook
create table if not exists fp_pricebook (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  category text,
  unit text default 'Each',
  price numeric(10,2) default 0,
  active boolean default true,
  created_at timestamptz default now()
);

-- Estimates
create table if not exists fp_estimates (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references fp_customers(id),
  estimate_number text unique not null,
  status text default 'Draft', -- Draft | Sent | Accepted | Declined
  line_items jsonb default '[]',
  subtotal numeric(10,2) default 0,
  tax_rate numeric(5,2) default 5.5,
  tax numeric(10,2) default 0,
  total numeric(10,2) default 0,
  notes text,
  valid_until date,
  sent_at timestamptz,
  created_by uuid references fp_users(id),
  created_at timestamptz default now()
);

-- Work Orders
create table if not exists fp_work_orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references fp_customers(id),
  estimate_id uuid references fp_estimates(id),
  wo_number text unique not null,
  status text default 'Scheduled', -- Scheduled | In Progress | Completed | Cancelled | On Hold
  scheduled_date date,
  scheduled_start text,
  scheduled_end text,
  tech_id uuid references fp_users(id),
  description text,
  notes text,
  total_price numeric(10,2) default 0,
  created_at timestamptz default now()
);

-- Inventory Locations (warehouse + vans)
create table if not exists fp_inv_locations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text default 'warehouse', -- warehouse | van
  address text,
  tech_id uuid references fp_users(id),
  active boolean default true
);

-- Inventory Items
create table if not exists fp_inv_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sku text,
  category text,
  unit text default 'Each',
  cost_price numeric(10,2) default 0,
  sale_price numeric(10,2) default 0,
  active boolean default true,
  created_at timestamptz default now()
);

-- Stock levels (item × location)
create table if not exists fp_inv_stock (
  id uuid primary key default gen_random_uuid(),
  item_id uuid references fp_inv_items(id),
  location_id uuid references fp_inv_locations(id),
  quantity numeric(10,2) default 0,
  updated_at timestamptz default now(),
  unique(item_id, location_id)
);

-- Transfer log
create table if not exists fp_inv_transfers (
  id uuid primary key default gen_random_uuid(),
  from_location_id uuid references fp_inv_locations(id),
  to_location_id uuid references fp_inv_locations(id),
  item_id uuid references fp_inv_items(id),
  quantity numeric(10,2) not null,
  notes text,
  transferred_by uuid references fp_users(id),
  transferred_at timestamptz default now()
);

-- Time punches (clock in/out)
create table if not exists fp_time_punches (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references fp_users(id),
  punch_in timestamptz not null,
  punch_out timestamptz,
  notes text,
  status text default 'pending', -- pending | approved | rejected
  approved_by uuid references fp_users(id),
  approved_at timestamptz,
  created_at timestamptz default now()
);

-- App settings (key/value)
create table if not exists fp_app_settings (
  key text primary key,
  value text
);

-- ─── RLS: enabled + wide-open allow_all (tighten when client goes live) ───────

alter table fp_users enable row level security;
alter table fp_customers enable row level security;
alter table fp_pricebook enable row level security;
alter table fp_estimates enable row level security;
alter table fp_work_orders enable row level security;
alter table fp_inv_locations enable row level security;
alter table fp_inv_items enable row level security;
alter table fp_inv_stock enable row level security;
alter table fp_inv_transfers enable row level security;
alter table fp_time_punches enable row level security;
alter table fp_app_settings enable row level security;

create policy allow_all on fp_users using (true) with check (true);
create policy allow_all on fp_customers using (true) with check (true);
create policy allow_all on fp_pricebook using (true) with check (true);
create policy allow_all on fp_estimates using (true) with check (true);
create policy allow_all on fp_work_orders using (true) with check (true);
create policy allow_all on fp_inv_locations using (true) with check (true);
create policy allow_all on fp_inv_items using (true) with check (true);
create policy allow_all on fp_inv_stock using (true) with check (true);
create policy allow_all on fp_inv_transfers using (true) with check (true);
create policy allow_all on fp_time_punches using (true) with check (true);
create policy allow_all on fp_app_settings using (true) with check (true);

-- ─── Seed data ────────────────────────────────────────────────────────────────

-- Admin: customplatformsolutions@gmail.com / Creatingvisions2026!
insert into fp_users (name, email, password_hash, role, phone) values
('Admin', 'customplatformsolutions@gmail.com', '424bba0feca33d6cd983e2a59feabbebe30e2bac9677e7d9d232aaf66bda468f', 'admin', '(262) 719-9122'),
('Todd Franz', 'todd@franzplumbing.com', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'tech', '(262) 719-9122')
on conflict (email) do nothing;

-- Default inventory locations
insert into fp_inv_locations (name, type, address) values
('Main Warehouse', 'warehouse', 'N39W27341 Hillside Grove, Pewaukee, WI'),
('Todd''s Van', 'van', null)
on conflict do nothing;

-- Sample pricebook
insert into fp_pricebook (name, category, unit, price) values
('Service Call / Diagnostic', 'Labor', 'Each', 125.00),
('Labor - Standard (per hour)', 'Labor', 'Hour', 95.00),
('Labor - Emergency (per hour)', 'Labor', 'Hour', 145.00),
('Water Heater Installation', 'Water Heater', 'Each', 850.00),
('Water Heater - 40gal Rheem', 'Water Heater', 'Each', 575.00),
('Faucet Installation', 'Fixtures', 'Each', 175.00),
('Toilet Installation', 'Fixtures', 'Each', 225.00),
('Garbage Disposal Installation', 'Fixtures', 'Each', 195.00),
('Drain Cleaning', 'Drain', 'Each', 175.00),
('Camera Inspection', 'Drain', 'Each', 275.00),
('Sump Pump Installation', 'Pump', 'Each', 650.00),
('Pipe Repair (per ft)', 'Pipe', 'Foot', 45.00),
('Shut-off Valve Replacement', 'Pipe', 'Each', 195.00),
('Water Softener Installation', 'Water Treatment', 'Each', 1200.00),
('Backflow Preventer Test', 'Backflow', 'Each', 85.00)
on conflict do nothing;

-- Sample customers
insert into fp_customers (first_name, last_name, company, phone, email, address, city, state, zip) values
('Mike', 'Johnson', null, '(262) 555-0101', 'mike.johnson@email.com', '123 Oak Street', 'Pewaukee', 'WI', '53072'),
('Sarah', 'Williams', 'Williams Properties LLC', '(262) 555-0102', 'sarah@williamsprop.com', '456 Maple Ave', 'Waukesha', 'WI', '53186'),
('Bob', 'Anderson', null, '(414) 555-0103', 'banderson@email.com', '789 Pine Road', 'Brookfield', 'WI', '53045')
on conflict do nothing;
