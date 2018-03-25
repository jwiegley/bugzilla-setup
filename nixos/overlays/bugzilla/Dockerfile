# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

FROM centos:7
MAINTAINER David Lawrence <dkl@mozilla.com>

# Environment configuration
ENV USER bugzilla
ENV HOME /home/$USER
ENV BUGS_DB_DRIVER mysql
ENV BUGZILLA_ROOT $HOME

# Distribution package installation
COPY rpm_list /tmp/rpm_list
RUN yum -y -q update \
    && yum -y -q groupinstall "Development Tools" \
    && yum -y -q install `cat /tmp/rpm_list` \
    && yum clean all

# User configuration
RUN useradd -m -G wheel -u 1000 -s /bin/bash $USER \
    && passwd -u -f $USER \
    && echo "bugzilla:bugzilla" | chpasswd

# Clone the code repo initially
ADD bugzilla.tar.xz /home

# Bugzilla dependencies and setup
# RUN /usr/bin/curl -o /usr/local/bin/cpanm -L https://cpanmin.us
COPY cpanm /usr/local/bin/cpanm
RUN chmod 755 /usr/local/bin/cpanm

COPY META.yml $HOME/META.yml
ENV CPANM /usr/local/bin/cpanm -l local --quiet --notest --skip-satisfied
ENV CPANMFLAGS --installdeps --with-recommends --with-all-features \
    --without-feature oracle --without-feature sqlite --without-feature pg .
RUN cd $HOME && $CPANM $CPANMFLAGS || exit 0
RUN cd $HOME && $CPANM $CPANMFLAGS
RUN cd $HOME && perl install-module.pl Linux::Pid
RUN rsync -a $HOME/local/lib/perl5/ $HOME/lib/
RUN rsync -a $HOME/local/lib/perl5/x86_64-linux-thread-multi/ $HOME/lib/
RUN cd $HOME && perl checksetup.pl --check-modules

COPY .htaccess $HOME/.htaccess
COPY checksetup_answers.txt /tmp/checksetup_answers.txt

RUN rm -rf $HOME/.cpanm
RUN yum remove -y mariadb-server
RUN chown -R $USER.$USER $HOME

# Networking
RUN echo "NETWORKING=yes" > /etc/sysconfig/network
EXPOSE 80

# Apache configuration
COPY bugzilla.conf /etc/httpd/conf.d/bugzilla.conf
RUN chown root.root /etc/httpd/conf.d/bugzilla.conf \
    && chmod 440 /etc/httpd/conf.d/bugzilla.conf

# Sudoer configuration
COPY sudoers /etc/sudoers
RUN chown root.root /etc/sudoers \
    && chmod 440 /etc/sudoers

# Supervisor
RUN easy_install supervisor
COPY supervisord.conf /etc/supervisord.conf
RUN chmod 700 /etc/supervisord.conf
RUN mkdir -p /var/log/supervisor

COPY startup.sh /startup.sh
RUN chmod 755 /startup.sh
CMD ["/startup.sh"]
