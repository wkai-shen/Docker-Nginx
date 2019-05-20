FROM nginx

LABEL maintainer="Custom NGINX Docker Maintainers <wkai96815@gmail.com>"

RUN set -x && \
	### After apt installing following tools we can inspect network inside the container
	### Even without installing them, we know container is connecting to internet and the private network through its host network configuration.
	apt update && \
	apt install -y --no-install-recommends \
		curl \
		iputils-ping \
		net-tools \
		## So we can use ifconfig
		traceroute \
		## Install PS command
		procps \
		## Use to create SSL files
		openssl

# Rename the default configuration file so NGINX will use mine instead.
RUN mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
# Copy all files and subdirectories in content directory (this directory itself is not copied!) under the build context, 
# where the Dockerfile is located into absolute static_site/ folder in the container.
COPY content /usr/share/nginx/static_site/
# Copy all files and subdirectories in conf directory under the build context, 
# where the Dockerfile is located into absolute conf.d/ folder in the container.
COPY conf /etc/nginx/conf.d/
# Copy all files and subdirectories in auth directory under the build context to absolute nginx/ folder in the container.
# The build context is where Dockerfile is saved.
COPY auth /etc/nginx/

# [HTTPS setup] Create a key and its certificate in one command.
## req means "request"
## -batch means using default for all the prompts.
## -x509 means generating an x509 certificate
## -nodes mean no use of DES encryption method
## -days means the length of time this cert will be valid
## -newkey means generating a new key with RSA 2048-bit key
## -keyout means saving the key in that path
## -out means saving the cert in that path
RUN mkdir -p /etc/nginx/ssl/private && mkdir -p /etc/nginx/ssl/certs
RUN openssl req -batch -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/private/nginx.key \
    -out /etc/nginx/ssl/certs/nginx.crt 2>/dev/null

# Use VOLUME to specify the destination of a volume inside a container.
# On the host-side, the volumes are auto-created with a very long ID-like name (ANONYMOUS volume)
# Drawback - Use VOLUME in Dockerfile will undo my following chmod commands
## RUN find /usr/share/nginx/static_site -type f -exec chmod 644 {} \; -print && \
##		find /usr/share/nginx/static_site -type d -exec chmod 755 {} \; -print
VOLUME /usr/share/nginx/static_site
VOLUME /etc/nginx/conf.d