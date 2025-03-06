FROM nginx:stable-alpine
COPY ./docker/nginx/wild/*  /etc/ssl/

# ADD Custom Config
ADD ./docker/nginx/nginx.conf /etc/nginx/nginx.conf

ADD ./docker/nginx/conf.d/sub.flagtickgroup.com.conf /etc/nginx/conf.d/sub.flagtickgroup.com.conf

# ADD ./resources/docker/nginx/default.conf /etc/nginx/conf.d/default.conf
# ADD ./docker/nginx/conf.d/local.flagtickgroup.com.conf /etc/nginx/conf.d/local.flagtickgroup.com.conf

# Make Directory - Workspace
RUN mkdir -p /var/www/vc.flagtickgroup
RUN mkdir -p /var/www/vc.flagtickgroup/public   

# ADD and set Group
RUN addgroup -g 1000 flagtickgroup && adduser -G flagtickgroup -g flagtick -s /bin/sh -D flagtick

# Set Group to Workspace
RUN chown flagtick:flagtickgroup /var/www/vc.flagtickgroup
RUN chown -R flagtick:flagtickgroup /var/www/vc.flagtickgroup/public

# Allow Nginx to access workspace
RUN chmod -R 755 /var/www/vc.flagtickgroup
RUN chmod -R 755 /var/www/vc.flagtickgroup/public


