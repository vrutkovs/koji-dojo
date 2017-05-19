alias kojitest="koji -c /opt/koji-clients/kojiadmin/config"
kojitest add-tag eng-rhel-7-build --include-all --arches="noarch"
kojitest add-tag eng-rhel-7-candidate --include-all --arches="noarch"
kojitest add-target eng-rhel-7-candidate eng-rhel-7-build eng-rhel-7-candidate
kojitest add-pkg --owner kojiadmin eng-rhel-7-build osbs-buildroot-docker
kojitest add-pkg --owner kojiadmin eng-rhel-7-candidate osbs-buildroot-docker
kojitest add-tag extras-rhel-7.2-build --include-all --arches="noarch"
kojitest add-tag extras-rhel-7.2-candidate --include-all --arches="noarch"
kojitest add-target extras-rhel-7.2-candidate extras-rhel-7.2-build extras-rhel-7.2-candidate
kojitest add-pkg --owner kojiadmin extras-rhel-7.2-build rsyslog-docker
kojitest add-pkg --owner=kojiadmin extras-rhel-7.2-candidate rsyslog-docker
kojitest add-tag release-e2e-test-1.0-rhel-7-container-build --include-all --arches="noarch"
kojitest add-tag release-e2e-test-1.0-rhel-7-candidate --include-all --arches="noarch"
kojitest add-target release-e2e-test-1.0-rhel-7-candidate release-e2e-test-1.0-rhel-7-container-build release-e2e-test-1.0-rhel-7-candidate

psql="psql --host=koji-db --username=koji koji"
echo "BEGIN WORK; INSERT INTO content_generator(name) VALUES('atomic-reactor'); COMMIT WORK;" | $psql
kojitest grant-cg-access kojibuilder atomic-reactor
kojitest grant-cg-access kojiadmin atomic-reactor

kojitest add-tag osbs-test-1.0-rhel-7-docker-build --include-all --arches="noarch"
kojitest add-tag osbs-test-1.0-rhel-7-docker-candidate --include-all --arches="noarch"
kojitest add-target osbs-test-1.0-rhel-7-docker-candidate osbs-test-1.0-rhel-7-docker-build osbs-test-1.0-rhel-7-docker-candidate
kojitest add-pkg --owner kojiadmin osbs-test-1.0-rhel-7-docker-build osbs-test-sandwich-docker
kojitest add-pkg --owner kojiadmin osbs-test-1.0-rhel-7-docker-candidate osbs-test-sandwich-docker

kojitest add-target eng-rhel-7-docker-candidate eng-rhel-7-build eng-rhel-7-candidate
kojitest add-pkg --owner kojiadmin osbs-test-1.0-rhel-7-docker-build osbs-test-hamburger-docker
kojitest add-pkg --owner kojiadmin osbs-test-1.0-rhel-7-docker-candidate osbs-test-hamburger-docker
