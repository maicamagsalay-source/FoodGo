// Receives PayMongo webhook events and updates the database.
// Deploy with:  supabase functions deploy paymongo-webhook --no-verify-jwt
// (PayMongo calls it, not a logged-in user, so JWT check is off. We verify PayMongo's signature instead.)
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

async function hmacHex(secret: string, message: string) {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(message));
  return Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

Deno.serve(async (req) => {
  const raw = await req.text();

  // ---- verify signature: header looks like  t=...,te=...,li=...
  const header = req.headers.get('paymongo-signature') ?? '';
  const parts: Record<string, string> = {};
  header.split(',').forEach((p) => {
    const [k, v] = p.split('=');
    parts[k] = v;
  });

  let event: any;
  try {
    event = JSON.parse(raw);
  } catch {
    return new Response('bad json', { status: 400 });
  }

  const live = event?.data?.attributes?.livemode === true;
  const expected = await hmacHex(Deno.env.get('PAYMONGO_WEBHOOK_SECRET')!, `${parts.t}.${raw}`);
  const received = live ? parts.li : parts.te;
  if (!received || received !== expected) {
    return new Response('invalid signature', { status: 401 });
  }

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const type: string = event.data.attributes.type;
  const resource = event.data.attributes.data; // the checkout session or payment
  console.log('PayMongo event:', type);

  if (type === 'checkout_session.payment.paid') {
    const checkoutId: string = resource.id;
    const payment = resource.attributes.payments?.[0];
    const orderId = Number(resource.attributes.metadata?.order_id ?? resource.attributes.reference_number);

    await admin.from('payments').update({
      status: 'paid',
      paymongo_payment_id: payment?.id ?? null,
      method: payment?.attributes?.source?.type ?? 'PayMongo',
      paid_at: new Date().toISOString(),
    }).eq('paymongo_checkout_id', checkoutId);

    // Mark paid; move a Pending order to Confirmed
    await admin.from('orders').update({ payment_status: 'paid' }).eq('id', orderId);
    await admin.from('orders').update({ status: 'confirmed' }).eq('id', orderId).eq('status', 'pending');
  } else if (type === 'payment.failed') {
    // Best effort: link back to the order through metadata if PayMongo includes it.
    const orderId = Number(resource?.attributes?.metadata?.order_id);
    if (orderId) {
      await admin.from('orders').update({ payment_status: 'failed' }).eq('id', orderId).eq('payment_status', 'pending');
      await admin.from('payments').update({ status: 'failed' }).eq('order_id', orderId).eq('status', 'pending');
    }
  }

  return new Response('ok', { status: 200 });
});
