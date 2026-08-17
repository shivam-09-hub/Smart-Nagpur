-- Enable Supabase Realtime for Smart Nagpur Tables
DO $$
BEGIN
  -- Add complaints table
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'complaints'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.complaints;
  END IF;

  -- Add vendor_applications table
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'vendor_applications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.vendor_applications;
  END IF;

  -- Add notifications table
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;

  -- Add complaint_timeline table
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'complaint_timeline'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.complaint_timeline;
  END IF;

  -- Add vendor_timeline table
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'vendor_timeline'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.vendor_timeline;
  END IF;

  -- Add admin_reviews table
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'admin_reviews'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.admin_reviews;
  END IF;
END $$;
