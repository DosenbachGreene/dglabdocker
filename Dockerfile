# Dosenbach and Greene Lab Docker Image
FROM ubuntu:xenial
MAINTAINER Andrew Van <vanandrew@wustl.edu>

### Install 4dfp tools ###
WORKDIR /opt
ENV NILSRC=/opt/4dfp_tools/NILSRC RELEASE=/opt/4dfp_tools/RELEASE REFDIR=/opt/4dfp_tools/atlas
ENV PATH=${PATH}:${RELEASE}:/opt/4dfp_tools/scripts
RUN apt-get update && apt-get install -y wget dirmngr tcsh curl make gfortran git unzip && \
    git clone https://github.com/DosenbachGreene/4dfp_tools.git && mkdir -p ${RELEASE} && \
    cd ${NILSRC} && git checkout dcm4dfpmod && \
    chmod u+x make_nil-tools.csh && ./make_nil-tools.csh && cd /opt/4dfp_tools && rm -r ${NILSRC} && \
	curl -L -o atlas.zip https://wustl.box.com/shared/static/fss7snz1a7i7xb8ezsdredrcpv2k1lmt.zip && \
	unzip atlas.zip && rm atlas.zip && apt-get remove -y make gfortran && apt-get autoremove -y

### Install stuff from neurodebian: connectome-workbench and fsleyes ###
RUN wget -O- http://neuro.debian.net/lists/xenial.us-ca.full | tee /etc/apt/sources.list.d/neurodebian.sources.list && \
    apt-get update && \
    apt-get install -y --allow-unauthenticated connectome-workbench fsleyes && \
    ln -s $(which FSLeyes) /usr/bin/fsleyes

### Compile and install fsl from source ###
WORKDIR /opt
ENV FSLDIR=/opt/fsl
RUN curl -O https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-5.0.10-sources.tar.gz && \
	tar zxf fsl-5.0.10-sources.tar.gz && \
	rm fsl-5.0.10-sources.tar.gz && \
    apt-get install -y build-essential libexpat1-dev libx11-dev libgl1-mesa-dev libglu1-mesa-dev zlib1g-dev && \
    sed -i '52iFSLCONFDIR=$FSLDIR/config' ${FSLDIR}/etc/fslconf/fsl.sh && \
	sed -i '53iFSLMACHTYPE=`$FSLDIR/etc/fslconf/fslmachtype.sh`' ${FSLDIR}/etc/fslconf/fsl.sh && \
	sed -i '57iexport FSLCONFDIR FSLMACHTYPE' ${FSLDIR}/etc/fslconf/fsl.sh && \
    sed -i "55s/(CC)/(CXX)/" ${FSLDIR}/src/miscvis/Makefile && \
	sed -i "13s/ mist-clean\";/\";/" ${FSLDIR}/build && \
    . ${FSLDIR}/etc/fslconf/fsl.sh && \
	cp -r ${FSLDIR}/config/linux_64-gcc4.8 ${FSLDIR}/config/${FSLMACHTYPE} && \
	cd ${FSLDIR} && ./build && \
    rm -r ${FSLDIR}/LICENCE ${FSLDIR}/README ${FSLDIR}/build ${FSLDIR}/build.log ${FSLDIR}/config ${FSLDIR}/extras ${FSLDIR}/include ${FSLDIR}/lib ${FSLDIR}/refdoc ${FSLDIR}/src && \
    apt-get remove -y build-essential && apt-get autoremove -y
ENV FSLOUTPUTTYPE=NIFTI_GZ FSLMULTIFILEQUIT=TRUE FSLTCLSH=${FSLDIR}/bin/fsltclsh FSLWISH=${FSLDIR}/fslwish PATH=${PATH}:${FSLDIR}/bin

### Install caret from my box link ###
RUN curl -L -o caret.zip https://wustl.box.com/shared/static/957c23jc3md68bgxskg7vgncq43j2aej.zip && apt-get install -y unzip && \
    unzip caret.zip && rm caret.zip && apt-get remove -y unzip
ENV PATH=${PATH}:/opt/caret/bin_linux64

# Remove neurodebian source & install python3 and nibabel
RUN rm /etc/apt/sources.list.d/neurodebian.sources.list && apt-get update && apt-get install -y python3 python3-pip && \
    pip3 install nibabel numpy

# Make directories to mount MATLAB and freesurfer under /opt; install Matlab dependencies
RUN apt-get update && apt-get install -y libpng12-dev libfreetype6-dev libblas-dev liblapack-dev gfortran build-essential && \
    mkdir -p /opt/MATLAB && mkdir -p /opt/freesurfer
ENV PATH=${PATH}:/opt/MATLAB/bin FREESURFER_HOME=/opt/freesurfer

# Goto Root
WORKDIR /
