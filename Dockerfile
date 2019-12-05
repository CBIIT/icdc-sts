# to run:
# docker run -dt -p 7000:7000 --name sts-gdc maj1/icdc:sts-gdc
# and browse to localhost:7000

FROM maj1/icdc:perlbrew-base
LABEL maintainer="Mark A. Jensen <mark -dot- jensen -at- nih -dot- com>"
EXPOSE 7000
WORKDIR /opns
COPY /sts /opns/sts
COPY /sts-db/sts-gdc.db /opns/sts-db/sts-gdc.db
COPY /start.sh /opns/sts/start.sh
WORKDIR /opns/sts
ENTRYPOINT ["./start.sh"]

