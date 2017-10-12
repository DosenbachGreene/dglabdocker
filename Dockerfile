# Dosenbach and Greene Lab Docker Image
FROM ubuntu:xenial
MAINTAINER Andrew Van <vanandrew@wustl.edu>

### Install 4dfp tools ###
WORKDIR /opt/4dfp
ENV NILSRC=/opt/4dfp/NILSRC RELEASE=/opt/4dfp/RELEASE
ENV PATH=${PATH}:${RELEASE}
RUN apt-get update && apt-get install -y wget dirmngr tcsh curl make gfortran git && \
    curl -O ftp://imaging.wustl.edu/pub/raichlab/4dfp_tools/4dfp_release.txt && \
    mkdir NILSRC && mkdir RELEASE && \
    cd ${NILSRC} && \
    curl -O ftp://imaging.wustl.edu/pub/raichlab/4dfp_tools/nil-tools.tar && \
    tar xvf nil-tools.tar && rm nil-tools.tar && \
    sed -i 's|(${OSTYPE}, linux)|(linux-gnu, linux-gnu)|g' */*.mak && \
	sed -i 's|chgrp program ${PROG}|#chgrp program ${PROG} # removed for ubuntu compilation|g' */*.mak && \
	sed -i 's|OBJECTS.*=.*nifti_4dfp.o 4dfp-format.o nifti-format.o split.o transform.o common-format.o parse_common.o|OBJECTS = nifti_4dfp.o -lm 4dfp-format.o -lm nifti-format.o -lm split.o -lm transform.o -lm common-format.o -lm parse_common.o -lm |g' nifti_4dfp/nifti_4dfp.mak && \
	sed -i 's|${TRX}/endianio.o ${TRX}/Getifh.o ${TRX}/rec.o ${IMGLIN}/t4_io.o|${TRX}/endianio.o -lm ${TRX}/Getifh.o -lm ${TRX}/rec.o -lm ${IMGLIN}/t4_io.o -lm|g' aff_conv/aff_conv.mak && \
	sed -i 's|${NII}/split.o ${NII}/transform.o ${NII}/4dfp-format.o ${NII}/nifti-format.o|${NII}/split.o -lm ${NII}/transform.o -lm ${NII}/4dfp-format.o -lm ${NII}/nifti-format.o -lm |g' aff_conv/aff_conv.mak && \
    sed -i '442i# get newest dcm_to_4dfp.c' make_nil-tools.csh && \
	sed -i '443icurl -L -O https://wustl.box.com/shared/static/ubof8682r88nbkxb7b4b1fsvfy4q1vr3.c' make_nil-tools.csh && \
	sed -i '444imv ubof8682r88nbkxb7b4b1fsvfy4q1vr3.c dcm_to_4dfp.c' make_nil-tools.csh && \
	sed -i "s/wget ftp/curl -O ftp/" make_nil-tools.csh && \
	sed -i "s/wget --help/curl --help/" make_nil-tools.csh && \
	sed -i "s/wget/curl/g" make_nil-tools.csh && \
    chmod u+x make_nil-tools.csh && ./make_nil-tools.csh && cd /opt/4dfp && rm -r ${NILSRC} && \
    cd ${RELEASE} && \
    curl -O ftp://imaging.wustl.edu/pub/raichlab/4dfp_tools/4dfp_scripts.tar && \
    tar xvf 4dfp_scripts.tar && rm 4dfp_scripts.tar && cd /opt/4dfp && \
    apt-get remove -y make gfortran && apt-get autoremove -y

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

# Goto Root
WORKDIR /
