-- Expense Tracker — Supabase schema & security setup
-- Run this in the Supabase SQL Editor (Dashboard > SQL Editor > New query).
--
-- Auth: users are managed by Supabase Auth (auth.users). The display name is
-- stored in user metadata at sign-up (key: "name"), so there is no separate
-- users table here.
--
-- IMPORTANT: For the demo sign-up flow to log the user in immediately, disable
-- "Confirm email" under Authentication > Providers > Email in the dashboard.

-- ---------------------------------------------------------------------------
-- Transactions
-- ---------------------------------------------------------------------------
create table if not exists public.transactions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  title      text,
  amount     numeric not null,
  type       text not null,            -- 'income' or 'expense'
  category   text,
  date       date not null,
  notes      text,
  created_at timestamptz not null default now()
);

create index if not exists transactions_user_id_idx on public.transactions (user_id);
create index if not exists transactions_user_date_idx on public.transactions (user_id, date);

-- ---------------------------------------------------------------------------
-- Budgets (one per user per month)
-- ---------------------------------------------------------------------------
create table if not exists public.budgets (
  id      bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  amount  numeric not null,
  month   text not null,               -- 'YYYY-MM'
  unique (user_id, month)
);

create index if not exists budgets_user_id_idx on public.budgets (user_id);

-- ---------------------------------------------------------------------------
-- Row-Level Security: each user can only access their own rows.
-- ---------------------------------------------------------------------------
alter table public.transactions enable row level security;
alter table public.budgets enable row level security;

-- transactions policies
drop policy if exists "transactions_select_own" on public.transactions;
create policy "transactions_select_own" on public.transactions
  for select using (auth.uid() = user_id);

drop policy if exists "transactions_insert_own" on public.transactions;
create policy "transactions_insert_own" on public.transactions
  for insert with check (auth.uid() = user_id);

drop policy if exists "transactions_update_own" on public.transactions;
create policy "transactions_update_own" on public.transactions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "transactions_delete_own" on public.transactions;
create policy "transactions_delete_own" on public.transactions
  for delete using (auth.uid() = user_id);

-- budgets policies
drop policy if exists "budgets_select_own" on public.budgets;
create policy "budgets_select_own" on public.budgets
  for select using (auth.uid() = user_id);

drop policy if exists "budgets_insert_own" on public.budgets;
create policy "budgets_insert_own" on public.budgets
  for insert with check (auth.uid() = user_id);

drop policy if exists "budgets_update_own" on public.budgets;
create policy "budgets_update_own" on public.budgets
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "budgets_delete_own" on public.budgets;
create policy "budgets_delete_own" on public.budgets
  for delete using (auth.uid() = user_id);
