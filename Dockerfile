# Dosenbach and Greene Lab Docker Image
FROM ubuntu:xenial
MAINTAINER Andrew Van <vanandrew@wustl.edu>

# Update and install sudo,wget,dirmngr
RUN apt-get update
RUN apt-get install -y sudo wget dirmngr

# Add Neurodebian Repo
RUN wget -O- http://neuro.debian.net/lists/xenial.us-tn.full | tee /etc/apt/sources.list.d/neurodebian.sources.list
RUN apt-key adv --recv-keys --keyserver hkp://pool.sks-keyservers.net:80 0xA5D32F012649A5A9
RUN apt-get update

# Install tcsh,curl,make,gfortran for compiling 4dfp
RUN apt-get install -y tcsh curl make gfortran

### Install 4dfp tools ###
WORKDIR /opt/4dfp
RUN curl -O ftp://imaging.wustl.edu/pub/raichlab/4dfp_tools/4dfp_release.txt
RUN mkdir NILSRC && mkdir RELEASE

# Set Environment Variables for 4dfp
ENV NILSRC /opt/4dfp/NILSRC
ENV RELEASE /opt/4dfp/RELEASE
ENV PATH ${PATH}:${RELEASE}

# start with the source code
WORKDIR ${NILSRC}
RUN curl -O ftp://imaging.wustl.edu/pub/raichlab/4dfp_tools/nil-tools.tar
RUN tar xvf nil-tools.tar && rm nil-tools.tar

# fix the few odd things having to do with compiling a new ubuntu system
RUN sed -i 's|(${OSTYPE}, linux)|(linux-gnu, linux-gnu)|g' */*.mak && \
	sed -i 's|chgrp program ${PROG}|#chgrp program ${PROG} # removed for ubuntu compilation|g' */*.mak && \
	sed -i 's|OBJECTS.*=.*nifti_4dfp.o 4dfp-format.o nifti-format.o split.o transform.o common-format.o parse_common.o|OBJECTS = nifti_4dfp.o -lm 4dfp-format.o -lm nifti-format.o -lm split.o -lm transform.o -lm common-format.o -lm parse_common.o -lm |g' nifti_4dfp/nifti_4dfp.mak && \
	sed -i 's|${TRX}/endianio.o ${TRX}/Getifh.o ${TRX}/rec.o ${IMGLIN}/t4_io.o|${TRX}/endianio.o -lm ${TRX}/Getifh.o -lm ${TRX}/rec.o -lm ${IMGLIN}/t4_io.o -lm|g' aff_conv/aff_conv.mak && \
	sed -i 's|${NII}/split.o ${NII}/transform.o ${NII}/4dfp-format.o ${NII}/nifti-format.o|${NII}/split.o -lm ${NII}/transform.o -lm ${NII}/4dfp-format.o -lm ${NII}/nifti-format.o -lm |g' aff_conv/aff_conv.mak

# inject JMK's edits to dcm_to_4dfp
RUN sed -i '442i# get newest dcm_to_4dfp.c' make_nil-tools.csh && \
	sed -i '443icurl -L -O https://wustl.box.com/shared/static/ubof8682r88nbkxb7b4b1fsvfy4q1vr3.c' make_nil-tools.csh && \
	sed -i '444imv ubof8682r88nbkxb7b4b1fsvfy4q1vr3.c dcm_to_4dfp.c' make_nil-tools.csh && \
	sed -i "s/wget ftp/curl -O ftp/" make_nil-tools.csh && \
	sed -i "s/wget --help/curl --help/" make_nil-tools.csh && \
	sed -i "s/wget/curl/g" make_nil-tools.csh

# begin the 4dfp tool code build ("make")
RUN chmod u+x make_nil-tools.csh
RUN ./make_nil-tools.csh

# grab the additional 4dfp supporting scripts
WORKDIR ${RELEASE}
RUN curl -O ftp://imaging.wustl.edu/pub/raichlab/4dfp_tools/4dfp_scripts.tar
RUN tar xvf 4dfp_scripts.tar && rm 4dfp_scripts.tar

# install git
RUN apt-get update; apt-get install -y git

# install connectome-workbench
RUN apt-get install -y connectome-workbench

# install fsl
WORKDIR /opt
RUN curl -O https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-5.0.10-sources.tar.gz
RUN tar zxf fsl-5.0.10-sources.tar.gz && rm fsl-5.0.10-sources.tar.gz
RUN apt-get install -y build-essential libexpat1-dev libx11-dev libgl1-mesa-dev libglu1-mesa-dev zlib1g-dev
ENV FSLDIR /opt/fsl
RUN sed -i '52iFSLCONFDIR=$FSLDIR/config' ${FSLDIR}/etc/fslconf/fsl.sh && \
	sed -i '53iFSLMACHTYPE=`$FSLDIR/etc/fslconf/fslmachtype.sh`' ${FSLDIR}/etc/fslconf/fsl.sh && \
	sed -i '57iexport FSLCONFDIR FSLMACHTYPE' ${FSLDIR}/etc/fslconf/fsl.sh
# Fix compiler error in FSL 5.0.10
RUN sed -i "55s/(CC)/(CXX)/" ${FSLDIR}/src/miscvis/Makefile
# Disable MIST compilation
RUN sed -i "13s/ mist-clean\";/\";/" ${FSLDIR}/build
RUN . ${FSLDIR}/etc/fslconf/fsl.sh && \
	cp -r ${FSLDIR}/config/linux_64-gcc4.8 ${FSLDIR}/config/${FSLMACHTYPE} && \
	cd ${FSLDIR} && \
	./build
RUN rm -r ${FSLDIR}/* !(bin|data|doc|etc|tcl)
ENV FSLOUTPUTYPE NIFTI_GZ
ENV FSLMULTIFILEQUIT TRUE
ENV FSLTCLSH ${FSLDIR}/bin/fsltclsh
ENV FSLWISH ${FSLDIR}/fslwish
ENV PATH ${PATH}:${FSLDIR}/bin

# install fsleyes
RUN apt-get install -y fsleyes
RUN ln -s $(which FSLeyes) /usr/bin/fsleyes

# clean-up
RUN apt-get upgrade -y
RUN apt-get remove -y make gfortran
RUN apt-get autoremove -y
WORKDIR /
