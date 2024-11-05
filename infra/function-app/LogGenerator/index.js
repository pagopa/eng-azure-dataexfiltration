const axios = require('axios');

module.exports = async function (context, req) {
    // Check if the request body contains the URL
    const url = req.body?.url;

    if (!url) {
        context.res = {
            status: 400,
            body: "Please provide a URL in the request body"
        };
        return;
    }

    try {
        // Make an HTTP GET request to the provided URL
        const response = await axios.get(url);
        
        // Return the response from the URL
        context.res = {
            status: response.status,
            body: response.data
        };
    } catch (error) {
        // Handle any errors that occur during the request
        context.res = {
            status: error.response?.status || 500,
            body: error.message || "An error occurred while making the HTTP request"
        };
    }
};
