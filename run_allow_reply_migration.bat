@echo off
echo Running allow_reply migration...
supabase db reset --db-url "postgresql://postgres.qxkmmkrisfbjqtfqjkww:Lotto2023runners!@aws-0-us-east-1.pooler.supabase.com:6543/postgres" --file add_allow_reply_to_admin_messages.sql
echo Migration complete!
pause

