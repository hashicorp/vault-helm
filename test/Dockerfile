FROM ubuntu:18.04

RUN apt-get update  
RUN apt-get install -y software-properties-common python-pip
RUN add-apt-repository ppa:rmescandon/yq && apt update

RUN apt-get install -y bats \
	jq 

RUN pip install yq

ADD . .
ADD test.sh /bin/test.sh
CMD test.sh
