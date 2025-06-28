import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Users = () => {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [newUser, setNewUser] = useState({ name: '', email: '' });
    const [isCreating, setIsCreating] = useState(false);

    useEffect(() => {
        fetchUsers();
    }, []);

    const fetchUsers = async () => {
        try {
            setLoading(true);
            const response = await axios.get('/api/users');
            setUsers(response.data);
        } catch (err) {
            setError('Failed to fetch users');
            console.error('Error fetching users:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleCreateUser = async (e) => {
        e.preventDefault();
        if (!newUser.name || !newUser.email) {
            setError('Name and email are required');
            return;
        }

        try {
            setIsCreating(true);
            setError(null);
            await axios.post('/api/users', newUser);
            setNewUser({ name: '', email: '' });
            fetchUsers();
        } catch (err) {
            setError('Failed to create user');
            console.error('Error creating user:', err);
        } finally {
            setIsCreating(false);
        }
    };

    const handleDeleteUser = async (userId) => {
        if (!window.confirm('Are you sure you want to delete this user?')) {
            return;
        }

        try {
            await axios.delete(`/api/users/${userId}`);
            fetchUsers();
        } catch (err) {
            setError('Failed to delete user');
            console.error('Error deleting user:', err);
        }
    };

    if (loading) {
        return <div className="loading">Loading users...</div>;
    }

    return (
        <div>
            <div className="card">
                <h2>User Management</h2>

                <form onSubmit={handleCreateUser} style={{ marginBottom: '2rem' }}>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr auto', gap: '1rem', alignItems: 'end' }}>
                        <div className="form-group">
                            <label htmlFor="name">Name</label>
                            <input
                                type="text"
                                id="name"
                                value={newUser.name}
                                onChange={(e) => setNewUser({ ...newUser, name: e.target.value })}
                                placeholder="Enter name"
                                required
                            />
                        </div>

                        <div className="form-group">
                            <label htmlFor="email">Email</label>
                            <input
                                type="email"
                                id="email"
                                value={newUser.email}
                                onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
                                placeholder="Enter email"
                                required
                            />
                        </div>

                        <button
                            type="submit"
                            className="button"
                            disabled={isCreating}
                        >
                            {isCreating ? 'Creating...' : 'Add User'}
                        </button>
                    </div>
                </form>

                {error && <div className="error">{error}</div>}

                <div>
                    <h3>Users ({users.length})</h3>
                    {users.length === 0 ? (
                        <p>No users found. Create your first user above.</p>
                    ) : (
                        <ul className="users-list">
                            {users.map((user) => (
                                <li key={user.id} className="user-item">
                                    <div className="user-info">
                                        <h3>{user.name}</h3>
                                        <p>{user.email}</p>
                                        <small>ID: {user.id}</small>
                                    </div>
                                    <button
                                        className="button"
                                        style={{ backgroundColor: '#f44336' }}
                                        onClick={() => handleDeleteUser(user.id)}
                                    >
                                        Delete
                                    </button>
                                </li>
                            ))}
                        </ul>
                    )}
                </div>
            </div>
        </div>
    );
};

export default Users; 