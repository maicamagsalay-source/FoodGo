// @ts-nocheck
// Creates a DYNAMIC QR Ph code (exact amount, single use, valid 30 min) for one order.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

const EXPIRY_SECONDS = 1800; // 30 minutes

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
        const { data: order } = await userClient.from('orders').select('*').eq('id', order_id).single();
        if (!order) return json({ error: 'Order not found' }, 404);
        if (order.payment_status === 'paid') return json({ error: 'Order already paid' }, 400);
        if (order.status === 'cancelled') return json({ error: 'Order was cancelled' }, 400);

        const total = Number(order.total);
        // TESTING ONLY: minimum amount check removed. Restore before going live:
        // if (total < 20) return json({ error: 'QR Ph needs a total of at least ₱20.' }, 400);

        const auth = 'Basic ' + btoa(Deno.env.get('PAYMONGO_SECRET_KEY')! + ':');
        const call = async (path: string, body: unknown) => {
            const r = await fetch('https://api.paymongo.com/v1' + path, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', Authorization: auth },
                body: JSON.stringify(body),
            });
            return { ok: r.ok, json: await r.json() };
        };

        // 1) payment intent (amount in centavos)
        const intent = await call('/payment_intents', {
            data: {
                attributes: {
                    amount: Math.round(total * 100),
                    currency: 'PHP',
                    payment_method_allowed: ['qrph'],
                    description: `Lamón Order #${order.id}`,
                    metadata: { order_id: String(order.id) },
                },
            },
        });
        if (!intent.ok) {
            console.error('intent error', JSON.stringify(intent.json));
            return json({ error: intent.json?.errors?.[0]?.detail ?? 'Could not start the QR payment.' }, 502);
        }
        const intentId = intent.json.data.id;
        const clientKey = intent.json.data.attributes.client_key;

        // 2) qrph payment method
        const method = await call('/payment_methods', {
            data: {
                attributes: {
                    type: 'qrph',
                    expiry_seconds: EXPIRY_SECONDS,
                    billing: {
                        name: order.customer_name,
                        email: user.email,
                        phone: order.phone,
                        address: { line1: order.address, city: 'N/A', state: 'N/A', postal_code: '0000', country: 'PH' },
                    },
                },
            },
        });
        if (!method.ok) {
            console.error('method error', JSON.stringify(method.json));
            return json({ error: method.json?.errors?.[0]?.detail ?? 'Could not create the QR code.' }, 502);
        }

        // 3) attach -> QR image
        const attach = await call(`/payment_intents/${intentId}/attach`, {
            data: { attributes: { payment_method: method.json.data.id, client_key: clientKey } },
        });
        if (!attach.ok) {
            console.error('attach error', JSON.stringify(attach.json));
            return json({ error: attach.json?.errors?.[0]?.detail ?? 'Could not create the QR code.' }, 502);
        }
        const image = attach.json.data.attributes.next_action?.code?.image_url;
        if (!image) return json({ error: 'PayMongo did not return a QR code.' }, 502);

        await admin.from('payments').insert({
            order_id: order.id,
            user_id: user.id,
            amount: total,
            method: 'qrph',
            paymongo_intent_id: intentId,
            status: 'pending',
        });

        return json({
            qr_image: image,
            expires_at: new Date(Date.now() + EXPIRY_SECONDS * 1000).toISOString(),
        });
    } catch (e) {
        console.error(e);
        return json({ error: 'Something went wrong' }, 500);
    }
});