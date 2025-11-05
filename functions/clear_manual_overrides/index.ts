import { serve } from 'std/server';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

serve(async (req) => {
  try {
    // Call the RPC that performs the cleanup
    const { data, error } = await supabase.rpc('clear_manual_overrides');
    if (error) {
      console.error('RPC error', error);
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }
    return new Response(JSON.stringify({ ok: true, data }), { status: 200 });
  } catch (e) {
    console.error('Unhandled error', e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
