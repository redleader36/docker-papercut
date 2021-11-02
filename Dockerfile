FROM ubuntu
LABEL author="redleader36"
LABEL version="1.0.0"
ARG PAPERCUT_URL="https://www.papercut.com/api/product/ng/latest/linux-x64/"

#RUN apk add --no-cache bash curl perl shadow && useradd papercut -m -d /home/papercut
RUN apt-get update && apt-get install -y \
    curl \
    cpio \
    sudo \
    supervisor \
 && rm -rf /var/lib/apt/lists/*
RUN useradd papercut -m -d /home/papercut
RUN curl -fSL $PAPERCUT_URL -o /installpc.sh && chmod +x /installpc.sh && /installpc.sh -e && rm /installpc.sh

RUN sed -i "s/manual=/manual=1/" /papercut/install
RUN sed -i "s/answered=/answered=1/" /papercut/install
RUN rm /papercut/LICENCE.TXT

USER papercut
RUN /papercut/install

USER root
RUN /home/papercut/MUST-RUN-AS-ROOT

RUN mkdir -p /var/log/supervisord
COPY supervisord.conf /supervisord.conf

HEALTHCHECK CMD curl -k --fail http://127.0.0.1:9191 || exit 1
EXPOSE 9191

WORKDIR /home/papercut/server/bin/linux-x64
ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["-c", "/supervisord.conf"]
