import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

interface IEmbedding {
  search: string;
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const model = new Supabase.ai.Session("gte-small");

Deno.serve(async (req) => {
  const payload: IEmbedding = await req.json();
  const { search } = payload;

  console.log(payload);

  // Generate embedding
  const embedding = await model.run(search, {
    mean_pool: true,
    normalize: true,
  });

  const { error, data } = await supabase.rpc("query_embeddings", {
    query_embedding: embedding,
    match_threshold: 0.4,
  });

  if (error) {
    console.error(error.message);
    return new Response(JSON.stringify({ error: error.message, data: null }), {
      status: 500,
    });
  }

  return new Response(
    JSON.stringify(
      // deno-lint-ignore no-explicit-any
      data.map((e: any) => e.post_id),
    ),
    { status: 200 },
  );
});
