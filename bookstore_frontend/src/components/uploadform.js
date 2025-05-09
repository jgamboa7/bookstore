import React, { useState, useCallback } from "react";
import PropTypes from "prop-types";
import axios from "axios";
import "./uploadform.css";

/**
 * Component for uploading documents with keywords
 * @param {Object} props - Component props
 * @param {Function} props.onUploadSuccess - Callback function after successful upload
 * @param {Function} props.onUploadError - Callback function after failed upload
 * @param {string} props.apiEndpoint - API endpoint for the upload
 * @param {string} props.getToken - Authentication token
 * @param {Array} props.allowedFileTypes - Array of allowed file extensions (e.g. ['.pdf', '.docx'])
 * @param {number} props.maxFileSizeMB - Maximum file size in MB
 */
const UploadForm = ({
  onUploadSuccess,
  onUploadError,
  apiEndpoint,
  getToken,
  allowedFileTypes = [".pdf", ".epub", ".docx"],
  maxFileSizeMB = 20
}) => {
  // State management
  const [file, setFile] = useState(null);
  const [keywords, setKeywords] = useState("");
  const [title, setTitle] = useState("");
  const [author, setAuthor] = useState("");
  const [excerpt, setExcerpt] = useState("");
  const [status, setStatus] = useState("");
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState(null);

  /**
   * Handle file selection
   * @param {Event} e - Change event from file input
   */
  const handleFileChange = useCallback((e) => {
    const selectedFile = e.target.files[0];
    
    if (!selectedFile) {
      return;
    }
    
    // Check file type if allowedFileTypes is provided
    if (allowedFileTypes && allowedFileTypes.length > 0) {
      const fileExtension = selectedFile.name.substring(selectedFile.name.lastIndexOf(".")).toLowerCase();
      if (!allowedFileTypes.includes(fileExtension)) {
        setError(`Invalid file type. Allowed types: ${allowedFileTypes.join(", ")}`);
        setFile(null);
        return;
      }
    }
    
    // Check file size
    const fileSizeInMB = selectedFile.size / (1024 * 1024);
    if (fileSizeInMB > maxFileSizeMB) {
      setError(`File size exceeds maximum limit of ${maxFileSizeMB}MB. Your file is ${fileSizeInMB.toFixed(2)}MB.`);
      setFile(null);
      return;
    }
    
    setFile(selectedFile);
    setError(null);
  }, [allowedFileTypes, maxFileSizeMB]);

  /**
   * Handle keywords input change
   * @param {Event} e - Change event from text input
   */
  const handleKeywordsChange = useCallback((e) => {
    setKeywords(e.target.value);
  }, []);

  /**
   * Handle form submission and file upload
   * @param {Event} e - Form submit event
   */
  const handleUpload = async (e) => {
    e.preventDefault();
    
    // Validate inputs
    if (!file) {
      setError("Please select a file");
      return;
    }
    
    if (!keywords.trim()) {
      setError("Please enter keywords");
      return;
    }

    if (!title.trim()) {
      setError("Please enter title");
      return;
    }

    if (!author.trim()) {
      setError("Please enter author");
      return;
    }
    
    // Clear previous status/errors
    setStatus("");
    setError(null);
    setIsUploading(true);
    
    const formData = new FormData();
    formData.append("file", file);
    formData.append("keywords", keywords);
    formData.append("title", title);
    formData.append("author", author);
    formData.append("excerpt", excerpt);
    
    try {
      // Set timeout and response type for large files
      const response = await axios.post(
        apiEndpoint,
        formData,
        {
          headers: {
            "Content-Type": "multipart/form-data",
            Authorization: `Bearer ${await getToken()}`
          },
          timeout: 60000, // 60 seconds timeout
          onUploadProgress: (progressEvent) => {
            const percentCompleted = Math.round((progressEvent.loaded * 100) / progressEvent.total);
            setStatus(`Uploading: ${percentCompleted}%`);
          }
        }
      );
      
      setStatus("Upload successful!");
      setFile(null);
      setKeywords("");
      setTitle("");
      setAuthor("");
      setExcerpt("");
      
      // Call success callback if provided
      if (onUploadSuccess && typeof onUploadSuccess === "function") {
        onUploadSuccess(response.data);
      }
    } catch (err) {
      const errorMessage = err.response?.data?.error || err.message || "Upload failed. Please try again.";
      
      setError(errorMessage);
      
      // Call error callback if provided
      if (onUploadError && typeof onUploadError === "function") {
        onUploadError(err);
      }
    } finally {
      setIsUploading(false);
    }
  };

  /**
   * Reset the form to its initial state
   */
  const handleReset = useCallback(() => {
    setFile(null);
    setKeywords("");
    setTitle("");
    setAuthor("");
    setExcerpt("");
    setStatus("");
    setError(null);
    
    // Reset the file input element
    const fileInput = document.getElementById('file-upload');
    if (fileInput) {
      fileInput.value = '';
    }
  }, []);

  return (
    <div className="upload-form-container">
      <form onSubmit={handleUpload} className="upload-form">
        <div className="form-group">
          <label htmlFor="file-upload" className="file-input-label">
            {file ? file.name : "Select document to upload"}
          </label>
          <input
            id="file-upload"
            type="file"
            onChange={handleFileChange}
            accept={allowedFileTypes.join(",")}
            className="file-input"
            disabled={isUploading}
          />
          {file && (
            <div className="file-info">
              <span>{(file.size / (1024 * 1024)).toFixed(2)} MB</span>
              <button 
                type="button" 
                className="clear-btn" 
                onClick={() => setFile(null)}
                disabled={isUploading}
              >
                ✕
              </button>
            </div>
          )}
        </div>

        <div className="form-group">
          <label htmlFor="title-input">Title:</label>
          <input
            id="title-input"
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Enter book title"
            className= "title-input"
            disabled={isUploading}
          />
        </div>

        <div className="form-group">
          <label htmlFor="author-input">Author:</label>
          <input
            id="author-input"
            type="text"
            value={author}
            onChange={(e) => setAuthor(e.target.value)}
            placeholder="Enter author name"
            className= "author-input"
            disabled={isUploading}
          />
        </div>

        <div className="form-group">
          <label htmlFor="excerpt-input">Excerpt:</label>
          <textarea
            id="excerpt-input"
            value={excerpt}
            onChange={(e) => setExcerpt(e.target.value)}
            placeholder="Enter a short excerpt or description"
            className= "excerpt-input"
            disabled={isUploading}
            rows={3}
          />
        </div> 
        
        <div className="form-group">
          <label htmlFor="keywords-input">Keywords (comma-separated):</label>
          <input
            id="keywords-input"
            type="text"
            value={keywords}
            onChange={handleKeywordsChange}
            placeholder="Enter keywords to index this document"
            className="keywords-input"
            disabled={isUploading}
          />
        </div>
        
        <div className="form-actions">
          <button 
            type="submit" 
            className="submit-btn" 
            disabled={isUploading || !file || !keywords.trim() || !title.trim() || !author.trim()}
          >
            {isUploading ? (
              <span className="loading-spinner"></span>
            ) : (
              "Upload Document"
            )}
          </button>
          
          <button 
            type="button" 
            className="reset-btn" 
            onClick={handleReset}
            disabled={isUploading}
          >
            Reset
          </button>
        </div>
        
        {error && <div className="error-message">{error}</div>}
        {status && !error && <div className="status-message">{status}</div>}
      </form>
    </div>
  );
};

UploadForm.propTypes = {
  onUploadSuccess: PropTypes.func,
  onUploadError: PropTypes.func,
  apiEndpoint: PropTypes.string.isRequired,
  getToken: PropTypes.func.isRequired,
  allowedFileTypes: PropTypes.arrayOf(PropTypes.string),
  maxFileSizeMB: PropTypes.number
};

export default UploadForm;