FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]

LABEL maintainer="MAP collaboration https://github.com/MapCollaboration/NangaParbat"

ENV LANG=C.UTF-8

WORKDIR /home

ARG DEPD=/home/dependencies

#set version of software to be used
ARG LHAPDF_VERS=6.5.4
ARG ROOT_VERS=root_v6.32.00.Linux-ubuntu22.04-x86_64-gcc11.4 	
ARG CMAKE_VERS=3.29.4
ARG CS_VERS=2.2.0
ARG APFELXX_VERS=4.8.0
ARG NP_VERS=1.5.0 #NangaParbat version

#update apt database
RUN echo deb http://dk.archive.ubuntu.com/ubuntu jammy main >> /etc/apt/sources.list \
 && echo deb http://dk.archive.ubuntu.com/ubuntu jammy-updates main >> /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y ca-certificates

#install -y compilers
RUN apt-get install -y gfortran \
 && apt-get install -y g++ gcc  \
 && apt-get install -y python3 python3-dev python-is-python3

#create directory for dependencies
RUN mkdir ${DEPD}

#install -y basic sysytem dependencies 
RUN apt-get install -y patch autoconf libtool make \
 && apt-get install -y gpg wget \
 && apt-get install -y vim

#install -y CMake
RUN wget https://apt.kitware.com/kitware-archive.sh \
 && chmod +x ./kitware-archive.sh && ./kitware-archive.sh \
 && apt-get install -y cmake \
 && rm kitware-archive.sh

##-- install -y project dependencies
#install -y yaml manager and numerical libraries
RUN apt-get install -y libyaml-cpp-dev \ 
 && apt-get install -y libeigen3-dev \
 && apt-get install -y libgsl-dev 

#install -y ceres-solver
RUN apt-get install -y libgoogle-glog-dev libgflags-dev libatlas-base-dev libsuitesparse-dev \
 && cd ${DEPD} \
 && wget http://ceres-solver.org/ceres-solver-${CS_VERS}.tar.gz \
 && tar zxf ceres-solver-${CS_VERS}.tar.gz && rm ceres-solver-${CS_VERS}.tar.gz \
 && mkdir ceres-bin && cd ceres-bin \
 && cmake ../ceres-solver-${CS_VERS} && make -j4 && make test \
 && make install \
 && cd .. &&  rm -r ceres-solver-${CS_VERS} && rm -r ceres-bin 

#install -y ROOT
RUN apt-get install -y binutils dpkg-dev libssl-dev libx11-dev \libxext-dev libxft-dev libxpm-dev libtbb-dev \
 &&  cd ${DEPD} && wget https://root.cern/download/${ROOT_VERS}.tar.gz \
 && ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
 && rm -rf /var/lib/apt/lists/*\
 && tar -xzvf ${ROOT_VERS}.tar.gz \
 && rm -f ${ROOT_VERS}.tar.gz \
 && echo ${DEPD}/root/lib >> /etc/ld.so.conf \
 && ldconfig

ENV ROOTSYS ${DEPD}/root \
 && PATH $ROOTSYS/bin:$PATH \
 && PYTHONPATH $ROOTSYS/lib:$PYTHONPATH \
 && CLING_STANDARD_PCH none

 #install -y lhapdf
RUN cd ${DEPD} && wget https://lhapdf.hepforge.org/downloads/?f=LHAPDF-${LHAPDF_VERS}.tar.gz -O LHAPDF-${LHAPDF_VERS}.tar.gz \
 && tar -xf LHAPDF-${LHAPDF_VERS}.tar.gz && rm -r LHAPDF-${LHAPDF_VERS}.tar.gz \
 && cd LHAPDF-${LHAPDF_VERS} \
 && PYTHON=$(which python3) ./configure && make && make install \
 && cd .. && rm -r LHAPDF-${LHAPDF_VERS}

RUN lhapdf install  NNPDF40_nnlo_as_01180 \
                    MMHT2014lo68cl \
                    DSS14_NLO_Pip \
                    MMHT2014nnlo68cl \
                    xFitterPI_NLO_EIG \
                    DSS14_NLO_PiSum

#install -y apfel++
RUN cd ${DEPD} && wget https://github.com/vbertone/apfelxx/archive/refs/tags/${APFELXX_VERS}.tar.gz \
 && tar -xf ${APFELXX_VERS}.tar.gz && mv apfelxx-${APFELXX_VERS} apfelxx && rm -r ${APFELXX_VERS}.tar.gz \
 && cd apfelxx && mkdir build && cd build \ 
 && cmake -DCMAKE_Fortran_COMPILER=/usr/bin/gfortran .. && make && make install \
 && echo /usr/local/lib >> /etc/ld.so.conf \
 && ldconfig

 ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH}:/usr/local/lib

##-- install -y NangaParbat
RUN wget https://github.com/MapCollaboration/NangaParbat/archive/refs/tags/v${NP_VERS}.tar.gz
RUN tar -xf v${NP_VERS}.tar.gz && mv NangaParbat-${NP_VERS} NangaParbat && rm -r v${NP_VERS}.tar.gz
RUN source ${DEPD}/root/bin/thisroot.sh && cd NangaParbat && mkdir build && cd build \
 && cmake .. && make && make install