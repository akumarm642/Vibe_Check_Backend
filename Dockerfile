# Stage 1: Build the Backend Application (Compile TypeScript)
# This stage installs development dependencies and compiles your TypeScript code into JavaScript.
FROM node:20-alpine AS backend_build

# Set the working directory inside the container for this stage.
# All subsequent commands in this stage will be executed relative to this directory.
WORKDIR /app

# Copy package.json and package-lock.json first.
# This helps Docker's build cache: if only these files change, Docker will re-run 'npm ci'.
# If only your source code changes, it can use the cached dependency installation layer, speeding up builds.
COPY package.json package-lock.json ./

# Install all dependencies (including devDependencies), as they are needed for TypeScript compilation.
RUN npm ci

# Copy the rest of your backend application source code into the container.
# This includes all your .ts files, configuration, etc.
COPY . .

# Compile TypeScript code into JavaScript.
# This command executes the "build" script defined in your backend's package.json.
# IMPORTANT: Your backend's package.json MUST have a script like: "build": "tsc".
# This will typically output the compiled JavaScript files into a 'dist' folder.
RUN npm run build

# Stage 2: Run the Compiled Backend Application in a Lightweight Container
# This stage creates the final, smaller runtime container.
# It only includes what's necessary to run the application, excluding build tools and devDependencies.
FROM node:20-alpine AS backend_runtime

# Set the working directory for the runtime stage.
WORKDIR /app

# Copy only production dependencies from there build stage's node_modules.
# This keeps the final image size minimal by omitting devDependencies.
COPY --from=backend_build /app/package.json /app/package-lock.json ./
RUN npm ci --omit=dev

#change14
# Copy the compiled JavaScript files from the 'backend_build' stage.
# This line assumes that 'npm run build' outputs your compiled JS to a 'dist' folder.
# If your TypeScript compiler (tsc) outputs to a different directory (e.g., 'build'),
# you must adjust '/app/dist' to match that output path.
COPY --from=backend_build /app/dist ./dist

# If your backend application needs to serve any static assets (e.g., images, PDFs,
# or other files that are not part of the frontend's NGINX serving), you would copy them here.
# For example:
# COPY --from=backend_build /app/public ./public

# Expose the port your backend application is configured to listen on.
# This informs Docker that this container listens on port 8888.
# IMPORTANT: Ensure your backend application's code (e.g., server.ts) is actually
# configured to listen on this specific port (e.g., `app.listen(8888, ...) or process.env.PORT`).
EXPOSE 8888

# Define the command to run when the container starts.
# This command executes your compiled JavaScript entry file.
# IMPORTANT: Adjust 'dist/server.js' to match the actual path to your
# compiled main JavaScript file within the 'dist' folder.
CMD ["node", "dist/server.js"]
