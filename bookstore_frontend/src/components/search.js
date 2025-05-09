import React, { useState } from 'react';
import { TextField, Button, Card, CardContent, Typography, Grid, CircularProgress } from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import DownloadIcon from '@mui/icons-material/Download';
import './search.css';

const Search = ({ getAuthToken, onSearchError }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [searchPerformed, setSearchPerformed] = useState(false);


  const handleSearchChange = (event) => {
    setSearchTerm(event.target.value);
    setError(null);
  };

  const handleSearch = async (e) => {
    e.preventDefault();
    
    if (!searchTerm.trim()) {
      setError('Please enter a search term');
      return;
    }

    setLoading(true);
    setError(null);
    setSearchResults([]);
    setSearchPerformed(true);

    try {
      const token = await getAuthToken();
      const searchEndpoint = process.env.REACT_APP_API_URI_SEARCH;
      const res = await fetch(`${searchEndpoint}?query=${encodeURIComponent(searchTerm)}`, {
        headers: {
          Authorization: `Bearer ${await token}`,
        },
      });
      
      if (!res.ok) {
        throw new Error(`Search failed with status: ${res.status}`);
      }
      
      const data = await res.json();
      setSearchResults(data.results || []);
    } catch (err) {
      console.error('Search error:', err);
      setError(`Failed to perform search: ${err.message}`);
      if (onSearchError) {
        onSearchError(err);
      }
    } finally {
      setLoading(false);
    }
  };

  const handleDownload = async (book_id) => {
    try {
      const token = await getAuthToken();
      const downloadEndpoint = process.env.REACT_APP_API_URI_DOWNLOAD;
      const response = await fetch(`${downloadEndpoint}?id=${encodeURIComponent(book_id)}`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${await token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Download request failed with status: ${response.status}`);
      }

      const data = await response.json();
      
      if (data.downloadUrl) {
        window.open(data.downloadUrl, '_blank');
      } else {
        throw new Error('No download URL returned');
      }
    } catch (err) {
      console.error('Download error:', err);
      setError(`Failed to download document: ${err.message}`);
      if (onSearchError) {
        onSearchError(err);
      }
    }
  }; 

  return (
    <div className="search-container">
      <Typography variant="h5" component="h2" gutterBottom>
        Famelga BookStore Search
      </Typography>

      <form onSubmit={handleSearch} className="search-form">
        <TextField
          fullWidth
          label="Search for books"
          variant="outlined"
          value={searchTerm}
          onChange={handleSearchChange}
          className="search-input"
          sx={{
            '& .MuiOutlinedInput-root': {
              borderRadius: '100px',
              boxShadow: '0 4px 16px rgba(245, 240, 240, 0.1)',
            }
          }}
        />
        <Button 
          type="submit" 
          variant="contained" 
          color="primary" 
          startIcon={<SearchIcon />}
          disabled={loading}
          className="search-button"
          sx={{
            minWidth: '100px',
            height: '56px',
            borderRadius: '4px',
            '&:hover': {
              backgroundColor: '#ff8124',
            },
            '&.Mui-disabled': {
              backgroundColor: '#a0a0a0',
            }
          }}
        >
          Search
        </Button>
      </form>

      {error && (
        <Typography color="error" className="search-error">
          {error}
        </Typography>
      )}

      {loading && (
        <div className="search-loading">
          <CircularProgress />
        </div>
      )}

      {searchResults.length > 0 ? (
        <div className="search-results">
          <Typography variant="h6" className="results-heading">
            Search Results ({searchResults.length})
          </Typography>
          <Grid container spacing={3}>
            {searchResults.map((result, index) => (
              <Grid item xs={12} sm={6} md={4} key={result.book_id || index}>
                <Card className="result-card" sx={{ height: '100%' }}>
                  <CardContent>
                    <Typography variant="h6" component="div" className="result-title">
                      {result.title || result.filename || 'Unnamed Document'}
                    </Typography>
                    {result.author && (
                    <Typography variant="body2" color="text.secondary" className="result-author">
                      Author: {result.author}
                    </Typography>
                    )}
                    {result.excerpt && (
                      <Typography variant="body2" className="result-excerpt">
                        {result.excerpt}
                      </Typography>
                    )}
                    <Button
                      size="small"
                      startIcon={<DownloadIcon />}
                      onClick={() => handleDownload(result.book_id)}
                      className="download-button"
                      sx={{ marginTop: '10px' }}
                    >
                      Download
                    </Button>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </div>
      ) : !loading && searchTerm && searchPerformed && (
        <Typography className="no-results">
          No results found. Try a different search term.
        </Typography>
      )}
    </div>
  );
};

export default Search;