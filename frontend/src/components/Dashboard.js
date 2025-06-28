import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Dashboard = () => {
    const [systemStatus, setSystemStatus] = useState({});
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const fetchSystemStatus = async () => {
            try {
                const [frontendRes, backendRes] = await Promise.all([
                    axios.get('/health'),
                    axios.get('/api/health')
                ]);

                setSystemStatus({
                    frontend: frontendRes.data,
                    backend: backendRes.data,
                    timestamp: new Date().toLocaleString()
                });
            } catch (err) {
                setError('Failed to fetch system status');
                console.error('Error fetching system status:', err);
            } finally {
                setLoading(false);
            }
        };

        fetchSystemStatus();
        const interval = setInterval(fetchSystemStatus, 30000); // Refresh every 30 seconds

        return () => clearInterval(interval);
    }, []);

    if (loading) {
        return <div className="loading">Loading system status...</div>;
    }

    if (error) {
        return <div className="error">{error}</div>;
    }

    return (
        <div>
            <div className="card">
                <h2>System Dashboard</h2>
                <p>Last updated: {systemStatus.timestamp}</p>
            </div>

            <div className="status-grid">
                <div className="status-card">
                    <div className="status-title">Frontend Service</div>
                    <div className="status-value">
                        {systemStatus.frontend?.status || 'Unknown'}
                    </div>
                </div>

                <div className="status-card">
                    <div className="status-title">Backend Service</div>
                    <div className="status-value">
                        {systemStatus.backend?.status || 'Unknown'}
                    </div>
                </div>

                <div className="status-card">
                    <div className="status-title">Database</div>
                    <div className="status-value">
                        {systemStatus.backend?.database || 'Unknown'}
                    </div>
                </div>

                <div className="status-card">
                    <div className="status-title">Uptime</div>
                    <div className="status-value">
                        {systemStatus.backend?.uptime || 'Unknown'}
                    </div>
                </div>
            </div>

            <div className="card">
                <h2>Quick Actions</h2>
                <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
                    <button
                        className="button"
                        onClick={() => window.open('http://localhost:3001', '_blank')}
                    >
                        Open Grafana
                    </button>
                    <button
                        className="button"
                        onClick={() => window.open('http://localhost:9090', '_blank')}
                    >
                        Open Prometheus
                    </button>
                    <button
                        className="button"
                        onClick={() => window.location.reload()}
                    >
                        Refresh Status
                    </button>
                </div>
            </div>
        </div>
    );
};

export default Dashboard; 