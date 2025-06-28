import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Monitoring = () => {
  const [metrics, setMetrics] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchMetrics = async () => {
      try {
        const response = await axios.get('/api/metrics');
        setMetrics(response.data);
      } catch (err) {
        setError('Failed to fetch metrics');
        console.error('Error fetching metrics:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchMetrics();
    const interval = setInterval(fetchMetrics, 10000); // Refresh every 10 seconds

    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return <div className="loading">Loading metrics...</div>;
  }

  if (error) {
    return <div className="error">{error}</div>;
  }

  return (
    <div>
      <div className="card">
        <h2>System Monitoring</h2>
        <p>Real-time metrics and system performance data</p>
      </div>

      <div className="metrics-grid">
        <div className="metric-card">
          <div className="metric-title">Application Metrics</div>
          <div>
            <p><strong>Total Requests:</strong> {metrics.totalRequests || 0}</p>
            <p><strong>Active Connections:</strong> {metrics.activeConnections || 0}</p>
            <p><strong>Error Rate:</strong> {metrics.errorRate || '0%'}</p>
            <p><strong>Average Response Time:</strong> {metrics.avgResponseTime || '0ms'}</p>
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-title">System Resources</div>
          <div>
            <p><strong>CPU Usage:</strong> {metrics.cpuUsage || '0%'}</p>
            <p><strong>Memory Usage:</strong> {metrics.memoryUsage || '0%'}</p>
            <p><strong>Disk Usage:</strong> {metrics.diskUsage || '0%'}</p>
            <p><strong>Network I/O:</strong> {metrics.networkIO || '0 MB/s'}</p>
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-title">Database Metrics</div>
          <div>
            <p><strong>Active Connections:</strong> {metrics.dbConnections || 0}</p>
            <p><strong>Query Count:</strong> {metrics.queryCount || 0}</p>
            <p><strong>Slow Queries:</strong> {metrics.slowQueries || 0}</p>
            <p><strong>Database Size:</strong> {metrics.dbSize || '0 MB'}</p>
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-title">Service Health</div>
          <div>
            <p><strong>Frontend Status:</strong> 
              <span style={{ color: metrics.frontendStatus === 'healthy' ? '#4CAF50' : '#f44336' }}>
                {metrics.frontendStatus || 'unknown'}
              </span>
            </p>
            <p><strong>Backend Status:</strong> 
              <span style={{ color: metrics.backendStatus === 'healthy' ? '#4CAF50' : '#f44336' }}>
                {metrics.backendStatus || 'unknown'}
              </span>
            </p>
            <p><strong>Database Status:</strong> 
              <span style={{ color: metrics.databaseStatus === 'healthy' ? '#4CAF50' : '#f44336' }}>
                {metrics.databaseStatus || 'unknown'}
              </span>
            </p>
            <p><strong>Last Check:</strong> {new Date().toLocaleTimeString()}</p>
          </div>
        </div>
      </div>

      <div className="card">
        <h2>Monitoring Tools</h2>
        <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
          <button 
            className="button"
            onClick={() => window.open('http://localhost:3001', '_blank')}
          >
            Open Grafana Dashboard
          </button>
          <button 
            className="button"
            onClick={() => window.open('http://localhost:9090', '_blank')}
          >
            Open Prometheus
          </button>
          <button 
            className="button"
            onClick={() => window.open('http://localhost:9100', '_blank')}
          >
            Open Node Exporter
          </button>
        </div>
      </div>

      <div className="card">
        <h2>Recent Alerts</h2>
        <div>
          {metrics.alerts && metrics.alerts.length > 0 ? (
            <ul style={{ listStyle: 'none', padding: 0 }}>
              {metrics.alerts.map((alert, index) => (
                <li key={index} style={{ 
                  padding: '1rem', 
                  marginBottom: '1rem', 
                  backgroundColor: alert.severity === 'critical' ? '#ffebee' : '#fff3e0',
                  borderLeft: `4px solid ${alert.severity === 'critical' ? '#f44336' : '#ff9800'}`,
                  borderRadius: '4px'
                }}>
                  <strong>{alert.title}</strong>
                  <p style={{ margin: '0.5rem 0 0 0' }}>{alert.message}</p>
                  <small>{new Date(alert.timestamp).toLocaleString()}</small>
                </li>
              ))}
            </ul>
          ) : (
            <p>No active alerts</p>
          )}
        </div>
      </div>
    </div>
  );
};

export default Monitoring; 