# Use the official NGINX image from Docker Hub
FROM nginx:latest

# Copy the custom NGINX configuration file to the container
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 8080 for Cloud Run
EXPOSE 8080

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]