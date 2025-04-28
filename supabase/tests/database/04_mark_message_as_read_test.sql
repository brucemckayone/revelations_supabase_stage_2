-- Test file to verify the mark_message_as_read function
BEGIN;

-- Plan the number of tests we're going to run
SELECT plan(5);

-- Create test users
INSERT INTO auth.users (id, email) VALUES 
    ('11111111-1111-1111-1111-111111111111', 'user1@test.com') ON CONFLICT (id) DO NOTHING;
INSERT INTO auth.users (id, email) VALUES
    ('22222222-2222-2222-2222-222222222222', 'user2@test.com') ON CONFLICT (id) DO NOTHING;
INSERT INTO auth.users (id, email) VALUES
    ('33333333-3333-3333-3333-333333333333', 'user3@test.com') ON CONFLICT (id) DO NOTHING;

-- Create a test room
INSERT INTO public.chat_rooms (id, name, type, created_by) VALUES 
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Test Room', 'private', '11111111-1111-1111-1111-111111111111');

-- Add participants (skip the creator who is added automatically by trigger)
INSERT INTO public.chat_participants (chat_room_id, user_id, role) VALUES 
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'member');

-- Add a test message
INSERT INTO public.chat_messages (id, chat_room_id, sender_id, message) VALUES 
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Test message');

-- Test 1: Function exists
SELECT has_function(
    'public', 
    'mark_message_as_read', 
    ARRAY['uuid', 'uuid'], 
    'mark_message_as_read function should exist'
);

-- Test 2: Message can be marked as read by a participant
SELECT is(
    mark_message_as_read('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222'),
    TRUE,
    'Participant should be able to mark message as read'
);

-- Check that the read receipt was created
SELECT ok(
    EXISTS(
        SELECT 1 FROM public.message_read_receipts 
        WHERE message_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb' 
        AND user_id = '22222222-2222-2222-2222-222222222222'
    ),
    'Read receipt should be created for the participant'
);

-- Test 3: Non-participant cannot mark message as read
SELECT is(
    mark_message_as_read('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333'),
    FALSE,
    'Non-participant should not be able to mark message as read'
);

-- Test 4: Message can be marked as read by the creator
SELECT is(
    mark_message_as_read('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111'),
    TRUE,
    'Creator should be able to mark message as read'
);

-- Test 5: Check that the participant's last_read_message_id gets updated
SELECT ok(
    EXISTS(
        SELECT 1 FROM public.chat_participants 
        WHERE chat_room_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' 
        AND user_id = '22222222-2222-2222-2222-222222222222'
        AND last_read_message_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
    ),
    'Participant last_read_message_id should be updated'
);

-- Finish the tests
SELECT * FROM finish();

ROLLBACK; 