FROM nginx:alpine
# Build context: rer-dsp-core/config/Gateway

# Remove o default.conf do nginx base — senão o entrypoint NÃO processa os templates
# (envsubst só gera conf.d/*.conf se o destino não existir).
RUN rm -f /etc/nginx/conf.d/default.conf

# Templates DSP (processados por envsubst no start; filtro NGINX_ENVSUBST_FILTER=^DSP_)
COPY nginx/ /etc/nginx/templates/

# Diretórios de cache graváveis (proxy_cache_path /var/cache/nginx/dsp)
RUN mkdir -p /var/cache/nginx/dsp && chown -R nginx:nginx /var/cache/nginx

EXPOSE 8080
