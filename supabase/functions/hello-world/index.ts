import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.1";

const openAIApiKey = Deno.env.get("OPENAI_API_KEY");
const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

serve(async (req: Request) => {
  try {
    const supabase = createClient(supabaseUrl!, supabaseServiceRoleKey!);
    const { postId } = (await req.json()) as {
      postId: string;
    };

    const { data } = await supabase
      .from("posts")
      .select("*")
      .eq("id", postId)
      .single();

    // Call OpenAI API to generate description
    const openAIResponse = await fetch(
      "https://api.openai.com/v1/chat/completions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${openAIApiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-3.5-turbo",
          messages: [
            {
              role: "user",
              content:
                `YOU MUST RETURN ONLY short and compelling whilst being descriptive ${data.content}
              }`,
            },
          ],
          max_tokens: 100,
        }),
      },
    );

    if (!openAIResponse.ok) {
      throw new Error(
        `OpenAI API responded with status ${openAIResponse.status}`,
      );
    }

    const openAIData = await openAIResponse.json();
    const generatedDescription = openAIData.choices[0].message.content;

    // Update the table with the generated description

    const { error } = await supabase
      .from("posts")
      .update({ description: generatedDescription })
      .eq("id", postId);

    if (error) {
      throw new Error(error.message);
    }

    return new Response(
      JSON.stringify({ success: true, description: generatedDescription }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("Error:", error.message);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
