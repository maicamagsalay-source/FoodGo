-- Run this in Supabase SQL Editor for an existing FoodGo database.
create or replace function public.cancel_my_order(p_order_id bigint)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  update public.orders
  set status = 'cancelled'
  where id = p_order_id
    and user_id = auth.uid()
    and status in ('pending', 'confirmed')
    and payment_status <> 'paid';

  if not found then
    raise exception 'Order cannot be cancelled';
  end if;
end;
$$;

revoke all on function public.cancel_my_order(bigint) from public, anon;
grant execute on function public.cancel_my_order(bigint) to authenticated;
