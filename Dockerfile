FROM debian:latest
LABEL maintainer="Laurie Stephey <lastephey@lbl.gov>"

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /srv

RUN \
    apt-get update      &&  \
    apt-get install         \
        --yes               \
        automake-1.15       \
        autoconf            \
        autotools-dev       \
        binutils            \
        gfortran            \
        liblapack-dev       \
        libtool             \
        libyaml-tiny-perl   \
        python3-pip         \
        wget

#alias python3 to python which metalwalls expects
RUN ln -s /usr/bin/python3 /usr/bin/python && \
    ln -s /usr/bin/pip3 /usr/bin/pip

RUN \
    wget http://www.mpich.org/static/downloads/3.3.2/mpich-3.3.2.tar.gz &&  \
    tar xvzf mpich-3.3.2.tar.gz     &&  \
    cd mpich-3.3.2                  &&  \
    autoreconf --install --force    &&  \
    ./configure                     &&  \
    make -j 4                       &&  \
    make install                    &&  \
    make clean                      &&  \
    cd ..                           &&  \
    rm mpich-3.3.2.tar.gz

RUN \
    pip3 install            \
        --no-cache-dir      \
        mpi4py              \
        numpy               \
        scipy               \
        mbuild              \
        signac-flow

#f90wrap problem pip installing (numpy path issue) so let's try manually
RUN \
    wget --no-check-certificate --content-disposition https://github.com/jameskermode/f90wrap/archive/v0.2.3.tar.gz && \
    tar xvzf f90wrap-0.2.3.tar.gz && \
    cd f90wrap-0.2.3 && \
    python3 setup.py install


#set some environment variables
ENV F90 mpif90
ENV F90FLAGS -g -O2 -fPIC -cpp
ENV LDFLAGS -llapack
ENV F2PY f2py
ENV F90WRAP f90wrap
ENV FCOMPILER gnu95
ENV J -J

#ok now that we have the requirements let try getting metalwalls
#also expects a config.mk file, but since we're setting env variables let's try to fake it
RUN \
    wget "https://gitlab.com/api/v4/projects/21583844/repository/archive.tar.gz?sha=c3c1969792e4673094dcba0396bb5cedaf4a6449" && \
	tar -xzf archive.tar.gz\?sha\=c3c1969792e4673094dcba0396bb5cedaf4a6449 && \
	rm archive.tar.gz\?sha\=c3c1969792e4673094dcba0396bb5cedaf4a6449 && \
	mv metalwalls-* metalwalls-custom && \
	cd metalwalls-custom && \
    > config.mk && \
    make -j 4 python && \
    echo $(pwd)

ENV PYTHONPATH "${PYTHONPATH}:/srv/metalwalls-custom/build/python"
