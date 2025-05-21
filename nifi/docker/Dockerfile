# Use a imagem original do NiFi como base
FROM apache/nifi:latest


# Instale as ferramentas necessárias (Ubuntu/Debian)
USER root
RUN apt-get update && \
    apt-get install python3-pip python3-venv sudo netcat-openbsd net-tools nano less -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --no-cache-dir kazoo

RUN echo "nifi ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN chmod 1777 /tmp

COPY --chown=nifi:nifi check_zookeeper.sh /opt/nifi/scripts/check_zookeeper.sh
RUN chmod +x /opt/nifi/scripts/check_zookeeper.sh

COPY --chown=nifi:nifi generate_tls.sh /opt/nifi/scripts/generate_tls.sh
RUN chmod +x /opt/nifi/scripts/generate_tls.sh

COPY --chown=nifi:nifi update_hosts.py /opt/nifi/scripts/update_hosts.py
RUN chmod +x /opt/nifi/scripts/update_hosts.py

COPY --chown=nifi:nifi register_pod.py /opt/nifi/scripts/register_pod.py
RUN chmod +x /opt/nifi/scripts/register_pod.py

COPY --chown=nifi:nifi custom-start.sh /opt/nifi/scripts/custom-start.sh
RUN chmod +x /opt/nifi/scripts/custom-start.sh

COPY --chown=nifi:nifi nifi-toolkit /opt/nifi/scripts/nifi-toolkit


ENTRYPOINT ["/opt/nifi/scripts/custom-start.sh"]

USER nifi





