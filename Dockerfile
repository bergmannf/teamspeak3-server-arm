FROM alpine AS qemu

RUN apk add curl && curl -L https://github.com/multiarch/qemu-user-static/releases/download/v4.2.0-6/qemu-arm-static -O && chmod guo+x qemu-arm-static
RUN curl -L https://github.com/multiarch/qemu-user-static/releases/download/v4.2.0-6/qemu-amd64-static -O && chmod guo+x qemu-amd64-static

FROM arm32v7/debian:bullseye

COPY --from=qemu qemu-arm-static /usr/bin

RUN dpkg --add-architecture amd64
RUN apt update
# Requires libstdc++6 for error while loading shared libraries: libstdc++.so.6: cannot open shared object file: No such file or directory
RUN apt install -y ca-certificates libstdc++6:amd64 binfmt-support libpipeline1 lsb-base libc6:amd64 wget bzip2 sudo

RUN set -eux; \
 addgroup --gid 9987 ts3server; \
 adduser -u 9987 --no-create-home --home /var/ts3server --ingroup ts3server --shell /usr/sbin/nologin --disabled-password ts3server; \
 install -d -o ts3server -g ts3server -m 775 /var/ts3server /var/run/ts3server /opt/ts3server

ENV PATH "${PATH}:/opt/ts3server"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/lib/"

ARG TEAMSPEAK_CHECKSUM=a8a65388bb1d32260d3568e7bfb7da264f58a1256799e30309589856e4b36b51
ARG TEAMSPEAK_URL=https://files.teamspeak-services.com/releases/server/3.12.0/teamspeak3-server_linux_amd64-3.12.0.tar.bz2

RUN set -eux; \
 wget "${TEAMSPEAK_URL}" -O server.tar.bz2; \
 echo "${TEAMSPEAK_CHECKSUM} *server.tar.bz2" | sha256sum -c -; \
 mkdir -p /opt/ts3server; \
 tar -xf server.tar.bz2 --strip-components=1 -C /opt/ts3server; \
 rm server.tar.bz2; \
 mv /opt/ts3server/*.so /opt/ts3server/redist/* /usr/local/lib; \
 ldconfig /usr/local/lib

# setup directory where user data is stored
VOLUME /var/ts3server/
WORKDIR /var/ts3server/

#  9987 default voice
# 10011 server query
# 30033 file transport
EXPOSE 9987/udp 10011 30033 

COPY entrypoint.sh /opt/ts3server
COPY --from=qemu qemu-amd64-static /usr/bin

ENTRYPOINT [ "entrypoint.sh" ]
CMD [ "ts3server" ]
