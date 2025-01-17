# Stage 1: Build stage for the application
FROM node:18 AS build-stage  # Use an official Node.js image for the build environment
WORKDIR /app                # Set the working directory inside the container
 
# Copy package files and set npm configurations
COPY package*.json /app/    # Copy the package.json and package-lock.json files to the working directory
RUN npm config set strict-ssl false  # Disable strict SSL for npm (can be removed if SSL issues are resolved)
RUN npm config set registry https://registry.npmjs.org  # Set the npm registry URL
RUN npm install             # Install the dependencies
 
# Copy application code and build the project
COPY ./ /app/               # Copy the rest of the application code to the working directory
ARG ENVVAR                  # Define a build argument for environment configuration
RUN npm run build -- --output-path=./dist/gtcaasui --configuration $ENVVAR  # Build the project based on the provided environment
 
# Stage 2: Final stage to serve the built application with Nginx
FROM nginx:1.25-alpine      # Use the official Nginx image (lightweight and production-ready)
COPY --from=build-stage /app/dist/gtcaasui/ /usr/share/nginx/html  # Copy the built application from the build stage
COPY ./nginx.conf /etc/nginx/conf.d/default.conf  # Copy custom Nginx configuration
 
# Expose the port on which the app will run
EXPOSE 80                   # Expose port 80 for HTTP traffic
 
# Command to run Nginx when the container starts
CMD ["nginx", "-g", "daemon off;"]
 
# Build and run commands for AWS ECR:
# docker build -t 682033485284.dkr.ecr.us-east-1.amazonaws.com/ecr-gtsaas:latest .
# docker run --name ecr-gtsaas-c -d -p 9199:80 682033485284.dkr.ecr.us-east-1.amazonaws.com/ecr-gtsaas:latest
