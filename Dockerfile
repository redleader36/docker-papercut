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
    whois \
    usbutils \
    cups \
    cups-client \
    cups-bsd \
    cups-filters \
    foomatic-db-compressed-ppds \
    printer-driver-all \
    openprinting-ppds \
    hpijs-ppds \
    hp-ppd \
    hplip \
    smbclient \
    printer-driver-cups-pdf \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*
RUN useradd papercut -m -d /home/papercut
RUN useradd \
    --groups=sudo,lp,lpadmin \
    --create-home \
    --home-dir=/home/print \
    --shell=/bin/bash \
    --password=$(mkpasswd print) \
    print \
&& sed -i '/%sudo[[:space:]]/ s/ALL[[:space:]]*$/NOPASSWD:ALL/' /etc/sudoers

# Configure the service's to be reachable
RUN /usr/sbin/cupsd \
    && while [ ! -f /var/run/cups/cupsd.pid ]; do sleep 1; done \
    && cupsctl --remote-admin --remote-any --share-printers \
    && kill $(cat /var/run/cups/cupsd.pid)

# Patch the default configuration file to only enable encryption if requested
RUN sed -e '0,/^</s//DefaultEncryption IfRequested\n&/' -i /etc/cups/cupsd.conf
EXPOSE 631

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
