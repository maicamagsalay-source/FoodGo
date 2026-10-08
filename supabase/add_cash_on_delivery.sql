-- Run once in Supabase SQL Editor for projects that already use the original schema.
alter table public.orders
  add column if not exists payment_method text not null default 'PayMongo';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'orders_payment_method_check'
      and conrelid = 'public.orders'::regclass
  ) then
    alter table public.orders
      add constraint orders_payment_method_check
      check (payment_method in ('PayMongo', 'Cash on Delivery'));
  end if;
end $$;

drop function if exists public.place_order(text, text, text, jsonb);
create or replace function public.place_order(
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
  v_fee numeric := 49;
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