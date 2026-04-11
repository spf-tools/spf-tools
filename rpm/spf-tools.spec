%{!?pkg_version: %global pkg_version 20250415}

Name:           spf-tools
Version:        %{pkg_version}
Release:        1%{?dist}
Summary:        Tools for querying and flattening SPF records
License:        Apache-2.0
URL:            https://github.com/edmundlod/spf-tools
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

Requires:       bind-utils

%description
A collection of shell scripts for querying DNS SPF records and expanding
them into flat lists of IP addresses and CIDR blocks. Used by postallow
to generate Postfix Postscreen allowlists from the SPF records of large,
trusted mail senders.

%prep
%autosetup

%build
# nothing to build — pure shell scripts

%install
install -d -m 755 %{buildroot}%{_bindir}/spf-tools
install -m 755 despf.sh cloudflare.sh compare.sh genspfzone.sh \
    iprange.sh mkblocks.sh mkzoneent.sh normalize.sh route53.sh \
    runspftools.sh simplify.sh xsel.sh dnsimple.sh \
    %{buildroot}%{_bindir}/spf-tools/
install -d -m 755 %{buildroot}%{_bindir}/spf-tools/include
install -m 644 include/*.sh %{buildroot}%{_bindir}/spf-tools/include/

%files
%license LICENSE
%doc README.md
%dir %{_bindir}/spf-tools
%{_bindir}/spf-tools/*.sh
%dir %{_bindir}/spf-tools/include
%{_bindir}/spf-tools/include/*.sh

%changelog
* Sat Apr 11 2026 Edmund Lodewijks <edmund@proteamail.com> - 20250415-1
- Initial RPM packaging
