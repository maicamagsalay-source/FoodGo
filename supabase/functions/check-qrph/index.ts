// The app calls this every 5 seconds. It asks PayMongo if the QR was paid and marks the order paid.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

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
        const { data: order } = await userClient.from('orders').select('id,payment_status').eq('id', order_id).single();
        if (!order) return json({ error: 'Order not found' }, 404);
        if (order.payment_status === 'paid') return json({ payment_status: 'paid' });

        const { data: rows } = await admin
            .from('payments')
            .select('id,paymongo_intent_id')
            .eq('order_id', order.id)
            .eq('method', 'qrph')
            .eq('status', 'pending');

        const auth = 'Basic ' + btoa(Deno.env.get('PAYMONGO_SECRET_KEY')! + ':');
        for (const row of rows ?? []) {
            if (!row.paymongo_intent_id) continue;
            const r = await fetch(`https://api.paymongo.com/v1/payment_intents/${row.paymongo_intent_id}`, {
                headers: { Authorization: auth },
            });
            if (!r.ok) continue;
            const attrs = (await r.json()).data.attributes;
            if (attrs.status === 'succeeded') {
                await admin.from('payments').update({
                    status: 'paid',
                    paymongo_payment_id: attrs.payments?.[0]?.id ?? null,
                    paid_at: new Date().toISOString(),
                }).eq('id', row.id);
                await admin.from('orders').update({ payment_status: 'paid' }).eq('id', order.id);
                await admin.from('orders').update({ status: 'confirmed' }).eq('id', order.id).eq('status', 'pending');
                return json({ payment_status: 'paid' });
            }
        }
        return json({ payment_status: 'pending' });
    } catch (e) {
        console.error(e);
        return json({ error: 'Something went wrong' }, 500);
    }
});