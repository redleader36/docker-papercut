FROM alpine
LABEL author="Nicklaus McClendon"
LABEL version="1.0.0"

WORKDIR /papercut
RUN apk add --no-cache bash curl perl
RUN curl -fSL 'https://cdn.papercut.com/files/pcng/17.x/pcng-setup-17.3.6-linux-x64.sh' -o /tmp/install.sh && chmod +x /tmp/install.sh
RUN target=/ /tmp/install.sh -e
COPY install-config .install-config
RUN /papercut/install --non-interactive
