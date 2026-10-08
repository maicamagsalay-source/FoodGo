// Creates a PayMongo Checkout Session for an order.
// The PayMongo SECRET key lives only here (as a Supabase secret), never in Flutter.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  try {
    const url = Deno.env.get('SUPABASE_URL')!;
    const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
      global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
    });
    const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return json({ error: 'Unauthorized' }, 401);

    const { order_id } = await req.json();

    // Read through the user's client: row level security guarantees it's THEIR order.
    const { data: order, error } = await userClient
      .from('orders')
      .select('*, order_items(*)')
      .eq('id', order_id)
      .single();
    if (error || !order) return json({ error: 'Order not found' }, 404);
    if (order.payment_status === 'paid') return json({ error: 'Order already paid' }, 400);
    if (order.status === 'cancelled') return json({ error: 'Order was cancelled' }, 400);

    // PayMongo amounts are in centavos (₱120.00 = 12000)
    const lineItems = order.order_items.map((i: any) => ({
      currency: 'PHP',
      amount: Math.round(Number(i.price) * 100),
      name: i.food_name,
      quantity: i.quantity,
    }));
    if (Number(order.delivery_fee) > 0) {
      lineItems.push({
        currency: 'PHP',
        amount: Math.round(Number(order.delivery_fee) * 100),
        name: 'Delivery fee',
        quantity: 1,
      });
    }

    const returnUrl = Deno.env.get('PAYMENT_RETURN_URL') ?? 'https://example.com/payment-done';
    const secret = Deno.env.get('PAYMONGO_SECRET_KEY')!;

    const pm = await fetch('https://api.paymongo.com/v1/checkout_sessions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Basic ' + btoa(secret + ':'),
      },
      body: JSON.stringify({
        data: {
          attributes: {
            line_items: lineItems,
            payment_method_types: ['qrph', 'gcash', 'paymaya', 'card', 'grab_pay'],
            description: `Lamón Order #${order.id}`,
            reference_number: String(order.id),
            metadata: { order_id: String(order.id) },
            success_url: returnUrl,
            cancel_url: returnUrl,
          },
        },
      }),
    });
    const result = await pm.json();
    if (!pm.ok) {
      console.error('PayMongo error', JSON.stringify(result));
      return json({ error: 'PayMongo could not create the payment' }, 502);
    }

    const checkoutId = result.data.id;
    const checkoutUrl = result.data.attributes.checkout_url;

    // Save the payment record (only the service role can write to payments)
    await admin.from('payments').insert({
      order_id: order.id,
      user_id: user.id,
      amount: order.total,
      method: 'PayMongo',
      paymongo_checkout_id: checkoutId,
      status: 'pending',
    });

    return json({ checkout_url: checkoutUrl });
  } catch (e) {
    console.error(e);
    return json({ error: 'Something went wrong' }, 500);
  }
});
