-- Create the error_logs table
CREATE TABLE error_logs (
    id BIGSERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    error_level VARCHAR(20) NOT NULL,
    error_message TEXT NOT NULL,
    error_code VARCHAR(50),
    source_file VARCHAR(255),
    line_number INTEGER,
    function_name VARCHAR(100),
    user_id UUID,
    session_id UUID,
    request_path VARCHAR(255),
    request_method VARCHAR(10),
    ip_address INET,
    user_agent TEXT,
    stack_trace TEXT,
    additional_data JSONB
);

-- Create an index on timestamp for faster querying
CREATE INDEX idx_error_logs_timestamp ON error_logs (timestamp);

-- Create a function to easily insert error logs
CREATE OR REPLACE FUNCTION log_error(
    p_error_level VARCHAR(20),
    p_error_message TEXT,
    p_error_code VARCHAR(50) DEFAULT NULL,
    p_source_file VARCHAR(255) DEFAULT NULL,
    p_line_number INTEGER DEFAULT NULL,
    p_function_name VARCHAR(100) DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_session_id UUID DEFAULT NULL,
    p_request_path VARCHAR(255) DEFAULT NULL,
    p_request_method VARCHAR(10) DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_stack_trace TEXT DEFAULT NULL,
    p_additional_data JSONB DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    INSERT INTO error_logs (
        error_level, error_message, error_code, source_file, line_number,
        function_name, user_id, session_id, request_path, request_method,
        ip_address, user_agent, stack_trace, additional_data
    ) VALUES (
        p_error_level, p_error_message, p_error_code, p_source_file, p_line_number,
        p_function_name, p_user_id, p_session_id, p_request_path, p_request_method,
        p_ip_address, p_user_agent, p_stack_trace, p_additional_data
    );
END;
$$ LANGUAGE plpgsql;

-- Create a view for easy querying of recent errors
CREATE VIEW recent_errors AS
SELECT *
FROM error_logs
WHERE timestamp >= NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC;

