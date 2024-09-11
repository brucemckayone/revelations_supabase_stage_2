-- Create the user_stripe_data table
CREATE TABLE public.user_stripe_data (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    customer_id TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create the invoices table
CREATE TABLE public.invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,
    currency TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    stripe_invoice_id TEXT,
    status TEXT NOT NULL DEFAULT 'draft',
    CONSTRAINT unique_user_invoice_combination UNIQUE (user_id, stripe_invoice_id)
);

-- Create indexes for faster lookups
CREATE INDEX idx_invoices_user_id ON public.invoices(user_id);
CREATE INDEX idx_invoices_status ON public.invoices(status);

-- Create the function to enforce a single draft invoice per user
CREATE OR REPLACE FUNCTION public.enforce_single_draft_invoice_per_user()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'draft' AND EXISTS (
        SELECT 1 FROM public.invoices 
        WHERE user_id = NEW.user_id AND status = 'draft' AND id != NEW.id
    ) THEN
        RAISE EXCEPTION 'User % already has a draft invoice.', NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to invoke the function before insert or update on invoices
CREATE TRIGGER trigger_check_single_draft_invoice_per_user
BEFORE INSERT OR UPDATE ON public.invoices
FOR EACH ROW
EXECUTE FUNCTION public.enforce_single_draft_invoice_per_user();

-- Create triggers to update the updated_at column
CREATE TRIGGER update_user_stripe_data_modtime
    BEFORE UPDATE ON public.user_stripe_data
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_invoices_modtime
    BEFORE UPDATE ON public.invoices
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();
