FROM --platform=linux/x86_64 ubuntu:xenial
LABEL author="redleader36"
LABEL version="1.0.0"
ARG PAPERCUT_URL="https://www.papercut.com/api/product/ng/latest/linux-x64/"
FROM --platform=linux/x86_64 ubuntu:xenial

RUN apt-get update


###### Install CUPS

# install cups
RUN apt-get install -y cups cups-filters cups-client whois sudo

# create admin user cups
# add user to lp, lpadmin
# set password to cups
# disable sudo password checking
RUN useradd \
  --groups=sudo,lp,lpadmin \
  --password=$(mkpasswd cups) \
  cups \
  && sed -i '/%sudo[[:space:]]/ s/ALL[[:space:]]*$/NOPASSWD:ALL/' /etc/sudoers

# create default printer by writing to the conf file
# this file is needed by papercut to monitor stuff
COPY printers.conf /etc/cups/printers.conf

COPY cups.conf /etc/cups/cupsd.conf
EXPOSE 631


###### Install papercut

RUN apt-get install -y cups curl cpio perlbrew

# Download papercut
RUN curl -L "${PAPERCUT_URL}" -o /pcng-setup.sh && chmod a+rx /pcng-setup.sh

# Create user && install papercut
RUN useradd -mUd /papercut papercut
RUN runuser -l papercut -c "/pcng-setup.sh --non-interactive" && rm -f /pcmf-setup.sh && /papercut/MUST-RUN-AS-ROOT

# Stopping Papercut services before capturing image
RUN /etc/init.d/papercut stop && /etc/init.d/papercut-web-print stop

# so that we can easily print a test file
# docker exec <container> runuser -l <user> "lp -d nul /lorem-ipsum.pdf"
# COPY lorem-ipsum.pdf /

COPY server.properties /papercut/server/server.properties
EXPOSE 9191 9192 9193


###### Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /

WORKDIR /papercut
ENTRYPOINT ["/entrypoint.sh"]
