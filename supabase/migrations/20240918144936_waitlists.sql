
create table waitlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

create table waitlist_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) DEFAULT null,
    waitlist_id UUID REFERENCES public.waitlists(id) NOT NULL,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

create or replace function join_waitlist(waitlist_id UUID, email VARCHAR(255), user_id UUID DEFAULT null)
    returns waitlist_entries as $$
    begin
        insert into waitlist_entries (waitlist_id, email, user_id)
        values (waitlist_id, email, user_id);
        return new;
    end;
    $$ language plpgsql;



