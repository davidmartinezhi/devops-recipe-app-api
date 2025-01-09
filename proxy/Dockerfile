# This is the image for proxy
# it is configured as a reverse proxy that:
    # uses nginx
    # accepts conections 
    # serves static and media files
    # fowards rest of connections to django app

# Use the unprivileged NGINX Alpine-based image.
FROM nginxinc/nginx-unprivileged:1-alpine
# Label the image with maintainer info.
LABEL maintainer="londonappdeveloper.com"

# Copy a template NGINX config file into the container.
COPY ./default.conf.tpl /etc/nginx/default.conf.tpl

# Copy the uwsgi_params file into the container (often used by Django + uWSGI setups).
COPY ./uwsgi_params /etc/nginx/uwsgi_params

# Copy the custom run script that will dynamically create the final NGINX config file.
COPY ./run.sh /run.sh

# Define environment variables used in the template config or run script.
ENV LISTEN_PORT=8000
ENV APP_HOST=app
ENV APP_PORT=9000

# Switch to the root user to perform system-level changes (e.g., directory creation, permissions).
USER root

RUN mkdir -p /vol/static && \
    mkdir -p /vol/media && \
    chmod 755 /vol && \
    chown -R nginx:nginx /vol && \
    touch /etc/nginx/conf.d/default.conf && \
    chown nginx:nginx /etc/nginx/conf.d/default.conf && \
    chmod +x /run.sh

    # 1. mkdir -p /vol/static: creates the directory /vol/static (with intermediate directories if needed).
    # 2. mkdir -p /vol/media: creates the directory /vol/media.
    # 3. chmod 755 /vol: sets the permissions for /vol to be readable/executable by everyone, writable by owner.
    # 4. chmod -R nginx:nginx /vol: changes the ownership of /vol (and all inside) to the nginx user and group.
    # 5. touch /etc/nginx/conf.d/default.conf: creates an empty default.conf file if it doesn't exist.
    # 6. chown nginx:nginx /etc/nginx/conf.d/default.conf: gives nginx ownership of default.conf.
    # 7. chmod +x /run.sh: makes the run script executable.


VOLUME /vol/static

USER nginx

VOLUME /vol/static
VOLUME /vol/media

CMD ["/run.sh"]
