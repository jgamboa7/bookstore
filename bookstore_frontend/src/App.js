import { Amplify } from 'aws-amplify';
import React, { useState } from 'react';
import { Authenticator } from '@aws-amplify/ui-react';
import { fetchAuthSession } from 'aws-amplify/auth';
import '@aws-amplify/ui-react/styles.css';
import './App.css';
import './auth.css';
import UploadForm from './components/uploadform';
import Search from './components/search';

// Amplify configuration
Amplify.configure({
  Auth: {
    Cognito: {
      region: 'eu-central-1',
      userPoolId: 'eu-central-1_WzD0a7j9d',
      userPoolClientId: '4hr3o9qh15r6ebhb6r2poabt8i',
    }
  }
});

function App() {
  const [activeTab, setActiveTab] = useState('search'); // Default to search tab
 
  const handleUploadSuccess = (data) => {
    console.log('Upload successful:', data);
    // You can add additional handling here if needed
  };

  const handleUploadError = (error) => {
    console.error('Upload error:', error);
    // You can add additional error handling here if needed
  };

  const handleSearchError = (error) => {
    console.error('Search process error:', error);
    // You can add additional error handling here if needed
  };

  return (
    <Authenticator>
      {({ signOut, user }) => {
        console.log(user);
        // Get the auth token for the API calls
        const getAuthToken = async () => {
          try {
            const session = await fetchAuthSession();
            return session.tokens?.idToken?.toString() || '';
          } catch (err) {
            console.error('Failed to get auth token:', err);
            return '';
          }
        };

        return (
          <div className="app-container">
            <header className="app-header">
              <div className="logo-container">
                <h1>Famelga Bookstore</h1>
              </div>
              <div className="user-controls">
                <span>Welcome, {user.signInDetails?.loginId}</span>
                <button className="sign-out-btn" onClick={signOut}>Sign out</button>
              </div>
            </header>
            
            <div className="mode-toggle">
              <button 
                className={`toggle-btn ${activeTab === 'search' ? 'active' : ''}`}
                onClick={() => setActiveTab('search')}
              >
                Search
              </button>
              <button 
                className={`toggle-btn ${activeTab === 'upload' ? 'active' : ''}`}
                onClick={() => setActiveTab('upload')}
              >
                Upload
              </button>
            </div>
            
            <main className="main-content">
              {activeTab === 'search' ? (
                <Search 
                  getAuthToken={getAuthToken}
                  onSearchError={handleSearchError}
                />
              ) : (
                <div className="upload-container">
                  <h2>Upload Document</h2>                
                  <UploadForm 
                    apiEndpoint={process.env.REACT_APP_API_URI_UPLOAD}
                    getToken={getAuthToken} //Pass the function, not the result
                    onUploadSuccess={handleUploadSuccess}
                    onUploadError={handleUploadError}
                    allowedFileTypes={[".pdf", ".epub", ".docx"]}
                    maxFileSizeMB={20}
                  />
                </div>
              )}
            </main>
          </div>
        );
      }}
    </Authenticator>
  );
}

export default App;