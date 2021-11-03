
FROM ubuntu:latest

RUN apt update
RUN apt install -y --no-install-recommends cron

ADD crontab /etc/cron.d/remove-jobs
RUN chmod 0644 /etc/cron.d/remove-jobs
RUN touch /var/log/cron.log

CMD cron && tail -f /var/log/cron.log
