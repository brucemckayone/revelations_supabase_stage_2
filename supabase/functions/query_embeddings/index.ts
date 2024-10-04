import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

interface IEmbedding {
  search: string;
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

const model = new Supabase.ai.Session("gte-small");

Deno.serve(async (req) => {
  try {
    const payload: IEmbedding = await req.json();
    const { search } = payload;

    console.log("Search query:", search);

    // Generate embedding
    const embedding = await model.run(search, {
      mean_pool: true,
      normalize: true,
    });

    console.log("Generated embedding:", embedding);

    const { data, error } = await supabase.rpc("query_embeddings", {
      query_embedding: embedding,
      match_threshold: 0.4,
    });

    if (error) {
      console.error("RPC Error:", error);
      throw error;
    }

    console.log("RPC Result:", data);

    return new Response(JSON.stringify(data.map((e: any) => e.post_id)), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Function error:", error);
    return new Response(
      JSON.stringify({
        error: error.message || "An error occurred",
        data: null,
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
