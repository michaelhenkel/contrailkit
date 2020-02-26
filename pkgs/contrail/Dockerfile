FROM linuxkit/kernel:4.19.99 AS ksrc

FROM linuxkit/alpine:3fdc49366257e53276c6f363956a4353f95d9a81 AS build
RUN apk add build-base elfutils-dev git curl

COPY --from=ksrc /kernel-dev.tar /
RUN tar xf kernel-dev.tar && \
      mkdir /vrouter && \
      cd /vrouter && \
      git clone https://github.com/Juniper/contrail-vrouter && \
      curl -OL https://github.com/michaelhenkel/make_vrouter/raw/master/vrouter_libs.tgz && \
      tar zxvf vrouter_libs.tgz
COPY vr_buildinfo.h /vrouter/contrail-vrouter/include/vr_buildinfo.h
COPY vr_buildinfo.c /vrouter/contrail-vrouter/dp-core/vr_buildinfo.c
RUN cd /vrouter/contrail-vrouter && \
      gcc -o dp-core/vr_buildinfo.o -c -O0 -DDEBUG -g -D__VR_X86_64__ -D__VR_SSE__ -D__VR_SSE2__ -Iinclude -I ../build/debug/vrouter/sandesh/gen-c -I ../src/contrail-common dp-core/vr_buildinfo.c && \
      make -C /usr/src/linux-headers-4.19.99-linuxkit M=/vrouter/contrail-vrouter SANDESH_HEADER_PATH=/vrouter/build/debug/vrouter SANDESH_SRC_ROOT=../build/kbuild/ SANDESH_EXTRA_HEADER_PATH=/vrouter/src/contrail-common
FROM alpine:3.9
COPY --from=build /vrouter/contrail-vrouter/vrouter.ko /tmp
COPY init_kmod.sh /init_kmod.sh
COPY vif /usr/bin/vif
RUN chmod +x /usr/bin/vif
ENTRYPOINT ["/bin/sh", "/init_kmod.sh"]
