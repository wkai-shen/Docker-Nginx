# Docker-Nginx
This repo stores the build context for building Nginx image.

## Build the image
Build my custom Nginx image based on the build context located in /vagrant_syn_content/docker-nignx
* repo name = wkaishen/nginx
* tag name = latest
```Shell
docker build -t wkaishen/nginx:latest /vagrant_syn_content/docker-nignx
```

## Instantiate a container
Run a container named as **mynginx1** based on the image = wkaishen/nginx:latest
* Link the port from 80 (container) to 8080 (docker host)
* Mount the volume named as nginx_vol_conf with /etc/nginx/conf.d already defined in Dockerfile
* Mount the volume named as nginx_vol_content with /usr/share/nginx/static_site already defined in Dockerfile
* Use **default bridge network** (docker0)
```Shell
docker run -d -p 8080:80 \
--name mynginx1 \
--mount source=nginx_vol_conf,target=/etc/nginx/conf.d \
--mount source=nginx_vol_content,target=/usr/share/nginx/static_site \
wkaishen/nginx:latest
```

Can not use bridge network with port forwarding to run Nginx container if we want Nginx to redirect browsers!!
Because `return 301 https://$server_addr$request_uri;` this $server_addr is the IP of the container and the browser can not redirect to that IP.
Let's use default host network to solve this issue.
```Shell
docker run -d \
--name mynginx1 \
--mount source=nginx_vol_conf,target=/etc/nginx/conf.d \
--mount source=nginx_vol_content,target=/usr/share/nginx/static_site \
--network host \
wkaishen/nginx:latest
```

## Modify Nginx configuration and content
The approach is referencing to [Nginx official site](https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-docker/#maintaining-content-and-configuration-files-in-the-container)
1. Create a container named as **mynginx1_files** based on alpine image and interactively into terminal
    - `--rm` will remove this container when exit it
    - run ash shell
      ```Shell
      docker run -it --rm --volumes-from mynginx1 --name mynginx1_files alpine /bin/ash
      ```
2. Edit the config file
```Shell
vi /etc/nginx/conf.d/mypetsite.local.conf
```
3. Test the configuration
```Shell
docker exec -t mynginx1 nginx -t
```
4. Reload the changes Nginx
```Shell
docker container exec -t mynginx1 nginx -s reload
```

## Security concerns
All the certificates used in Nginx server should not be stored in Github. It would be better to use [docker secrets](https://docs.docker.com/compose/compose-file/#secrets)
to secure them. The [steps](https://serverfault.com/questions/871090/how-to-use-docker-secrets-without-a-swarm-cluster) to use docker secrets without creating swarm.
