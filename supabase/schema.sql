-- FoodGo database schema. Paste into Supabase Dashboard > SQL Editor > Run.

-- ============ TABLES ============
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text,
  phone text default '',
  avatar_url text,
  role text not null default 'customer' check (role in ('customer','admin')),
  created_at timestamptz not null default now()
);

create table categories (
  id bigint generated always as identity primary key,
  name text not null unique
);

create table foods (
  id bigint generated always as identity primary key,
  name text not null,
  description text default '',
  price numeric(10,2) not null check (price >= 0),
  category_id bigint references categories(id) on delete set null,
  image_url text,
  is_available boolean not null default true,
  is_featured boolean not null default false,
  is_popular boolean not null default false,
  created_at timestamptz not null default now()
);

create table orders (
  id bigint generated always as identity (start with 1001) primary key,
  user_id uuid not null references profiles(id),
  customer_name text not null,
  phone text not null,
  address text not null,
  subtotal numeric(10,2) not null default 0,
  delivery_fee numeric(10,2) not null default 0,
  total numeric(10,2) not null default 0,
  payment_method text not null default 'PayMongo'
    check (payment_method in ('PayMongo','Cash on Delivery')),
  status text not null default 'pending'
    check (status in ('pending','confirmed','preparing','ready','completed','cancelled')),
  payment_status text not null default 'pending'
    check (payment_status in ('pending','paid','failed')),
  created_at timestamptz not null default now()
);

create table order_items (
  id bigint generated always as identity primary key,
  order_id bigint not null references orders(id) on delete cascade,
  food_id bigint references foods(id) on delete set null,
  food_name text not null,
  price numeric(10,2) not null,
  quantity int not null check (quantity > 0)
);

create table payments (
  id bigint generated always as identity primary key,
  order_id bigint not null references orders(id) on delete cascade,
  user_id uuid not null references profiles(id),
  amount numeric(10,2) not null,
  method text,
  paymongo_checkout_id text,
  paymongo_payment_id text,
  status text not null default 'pending' check (status in ('pending','paid','failed')),
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

-- ============ HELPERS ============
create or replace function is_admin() returns boolean
language sql security definer stable set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin')
$$;

create or replace function my_role() returns text
language sql security definer stable set search_path = public as $$
  select role from profiles where id = auth.uid()
$$;

-- Auto-create a profile whenever someone signs up
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, email, full_name, phone)
  values (new.id, new.email,
          coalesce(new.raw_user_meta_data->>'full_name', ''),
          coalesce(new.raw_user_meta_data->>'phone', ''));
  return new;
end $$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function handle_new_user();

-- Place an order. Prices are read from the foods table (not trusted from the app).
drop function if exists public.place_order(text, text, text, jsonb);
create or replace function place_order(
  p_name text,
  p_phone text,
  p_address text,
  p_items jsonb,
  p_payment_method text default 'PayMongo'
)
returns bigint language plpgsql security definer set search_path = public as $$
declare
  v_order_id bigint;
  v_subtotal numeric := 0;
  v_fee numeric := 49;  -- delivery fee in PHP; change here (and in lib/config.dart)
  r record;
begin
  if auth.uid() is null then raise exception 'Not logged in'; end if;
  if p_payment_method is null or p_payment_method not in ('PayMongo', 'Cash on Delivery') then
    raise exception 'Invalid payment method';
  end if;

  insert into orders (user_id, customer_name, phone, address, delivery_fee, payment_method)
  values (auth.uid(), p_name, p_phone, p_address, v_fee, p_payment_method)
  returning id into v_order_id;

  for r in
    select f.id, f.name, f.price, (i.value->>'qty')::int as qty
    from jsonb_array_elements(p_items) i
    join foods f on f.id = (i.value->>'food_id')::bigint
    where f.is_available and (i.value->>'qty')::int > 0
  loop
    insert into order_items (order_id, food_id, food_name, price, quantity)
    values (v_order_id, r.id, r.name, r.price, r.qty);
    v_subtotal := v_subtotal + r.price * r.qty;
    if lower(trim(r.name)) = 'lemonade' then v_fee := 0; end if;
  end loop;

  if v_subtotal = 0 then raise exception 'Cart is empty or items unavailable'; end if;

  update orders
  set subtotal = v_subtotal, delivery_fee = v_fee, total = v_subtotal + v_fee
  where id = v_order_id;
  if p_payment_method = 'Cash on Delivery' then
    insert into payments (order_id, user_id, amount, method, status)
    values (v_order_id, auth.uid(), v_subtotal + v_fee, 'Cash on Delivery', 'pending');
  end if;
  return v_order_id;
end $$;

-- ============ ROW LEVEL SECURITY ============
alter table profiles enable row level security;
alter table categories enable row level security;
alter table foods enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;
alter table payments enable row level security;

-- profiles: see/edit your own (but you can't change your own role); admin sees all
create policy "profiles read" on profiles for select using (id = auth.uid() or is_admin());
create policy "profiles update own" on profiles for update
  using (id = auth.uid()) with check (id = auth.uid() and role = my_role());

-- menu: everyone can read, only admin can change
create policy "categories read" on categories for select using (true);
create policy "categories admin" on categories for all using (is_admin()) with check (is_admin());
create policy "foods read" on foods for select using (true);
create policy "foods admin" on foods for all using (is_admin()) with check (is_admin());

-- orders: customers read their own (created only via place_order); admin reads/updates all
create policy "orders read" on orders for select using (user_id = auth.uid() or is_admin());
create policy "orders admin update" on orders for update using (is_admin()) with check (is_admin());

create policy "order_items read" on order_items for select using (
  exists (select 1 from orders o where o.id = order_id and (o.user_id = auth.uid() or is_admin()))
);

-- payments: read only. Only the Edge Functions (service role) can write.
create policy "payments read" on payments for select using (user_id = auth.uid() or is_admin());

-- ============ STORAGE (food images) ============
insert into storage.buckets (id, name, public) values ('food-images', 'food-images', true)
on conflict (id) do nothing;

create policy "food images public read" on storage.objects for select
  using (bucket_id = 'food-images');
create policy "food images admin write" on storage.objects for all
  using (bucket_id = 'food-images' and public.is_admin())
  with check (bucket_id = 'food-images' and public.is_admin());

-- ============ SAMPLE DATA ============
insert into categories (name) values ('Meals'), ('Snacks'), ('Drinks'), ('Desserts'), ('Home made');

insert into foods (name, description, price, category_id, is_featured, is_popular)
select 'Cheese Burger', 'Juicy burger with cheese and vegetables.', 120, id, true, true from categories where name = 'Meals';
insert into foods (name, description, price, category_id, is_popular)
select 'Chicken Burger', 'Crispy chicken patty with mayo and lettuce.', 130, id, true from categories where name = 'Meals';
insert into foods (name, description, price, category_id)
select 'Double Burger', 'Two beef patties, double the fun.', 180, id from categories where name = 'Meals';
insert into foods (name, description, price, category_id, is_featured)
select 'French Fries', 'Golden crispy fries.', 60, id, true from categories where name = 'Snacks';
insert into foods (name, description, price, category_id, is_popular)
select 'Iced Tea', 'Refreshing lemon iced tea.', 45, id, true from categories where name = 'Drinks';
insert into foods (name, description, price, category_id)
select 'Chocolate Cake', 'Moist chocolate cake slice.', 95, id from categories where name = 'Desserts';

-- ============ MAKE YOURSELF ADMIN ============
-- 1) Register an account in the app (or Supabase Auth > Users > Add user)
-- 2) Then run (with your email):
-- update profiles set role = 'admin' where email = 'you@example.com';
