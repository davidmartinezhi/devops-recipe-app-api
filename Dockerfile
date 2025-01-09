# Use the official Python 3.9 image based on Alpine Linux version 3.13 as the base.
FROM python:3.9-alpine3.13

# Label the image with maintainer information.
LABEL maintainer="londonappdeveloper.com"

# Disable Python output buffering to ensure logs are shown immediately.
ENV PYTHONUNBUFFERED 1

# Define a build argument for the user ID.
ARG UID=101

# Copy the main requirements file into a temporary location in the container.
COPY ./requirements.txt /tmp/requirements.txt

# Copy the development requirements file into a temporary location in the container.
COPY ./requirements.dev.txt /tmp/requirements.dev.txt

# Copy the scripts folder to the container.
COPY ./scripts /scripts

# Copy the application code into the container.
COPY ./app /app

# Set the working directory to /app inside the container.
WORKDIR /app

# Expose port 8000 (commonly used by Django for local development).
EXPOSE 8000

# Define a build argument to control whether or not we install dev dependencies.
ARG DEV=false

# Execute a series of commands:
# 1. Create a new virtual environment in /py.
# 2. Upgrade pip to the latest version.
# 3. Install some required packages (Postgres client and JPEG dev libraries).
# 4. Install temporary build dependencies needed to compile Python packages (build-base, postgresql-dev, etc.).
# 5. Install the production requirements from requirements.txt.
# 6. If DEV is true, also install the dev requirements from requirements.dev.txt.
# 7. Remove the /tmp directory to clean up.
# 8. Remove the temporary build dependencies to reduce image size.
# 9. Create a new system user (django-user) with no password and a specific UID for running the application.
# 10. Create directories for media and static files under /vol/web.
# 11. Set the ownership of /vol/web to the django-user.
# 12. Set appropriate file permissions on /vol/web.
# 13. Make all scripts in /scripts executable.
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client jpeg-dev && \
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev zlib zlib-dev linux-headers && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp && \
    apk del .tmp-build-deps && \
    adduser \
        --uid $UID \
        --disabled-password \
        --no-create-home \
        django-user && \
    mkdir -p /vol/web/media && \
    mkdir -p /vol/web/static && \
    chown -R django-user:django-user /vol/web && \
    chmod -R 755 /vol/web && \
    chmod -R +x /scripts

# Add /scripts and the virtual environment's bin folder to the PATH environment variable.
ENV PATH="/scripts:/py/bin:$PATH"

# Switch to the django-user for running the application (no root access).
USER django-user

# Mark /vol/web/media and /vol/web/static as volumes to persist and share data.
VOLUME /vol/web/static
VOLUME /vol/web/media

# Set the default command to run the "run.sh" script when this container starts.
CMD ["run.sh"]
