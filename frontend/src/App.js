import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import './App.css';
import Dashboard from './components/Dashboard';
import Users from './components/Users';
import Monitoring from './components/Monitoring';

function App() {
    return (
        <Router>
            <div className="App">
                <nav className="navbar">
                    <div className="nav-container">
                        <h1 className="nav-logo">DevOps Pipeline</h1>
                        <ul className="nav-menu">
                            <li className="nav-item">
                                <Link to="/" className="nav-link">Dashboard</Link>
                            </li>
                            <li className="nav-item">
                                <Link to="/users" className="nav-link">Users</Link>
                            </li>
                            <li className="nav-item">
                                <Link to="/monitoring" className="nav-link">Monitoring</Link>
                            </li>
                        </ul>
                    </div>
                </nav>

                <main className="main-content">
                    <Routes>
                        <Route path="/" element={<Dashboard />} />
                        <Route path="/users" element={<Users />} />
                        <Route path="/monitoring" element={<Monitoring />} />
                    </Routes>
                </main>
            </div>
        </Router>
    );
}

export default App; 