FROM ubuntu
COPY ./ /app
WORKDIR /app/deb
RUN ln -sf /usr/share/zoneinfo/EST /etc/localtime && apt-get update && apt-get install git -y && git clone https://github.com/sorhajy/wireguard_aws.git 
CMD cd wireguard/deb && ./install.sh