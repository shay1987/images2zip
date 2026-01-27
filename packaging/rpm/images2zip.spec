Name:           images2zip
Version:        1.0.0
Release:        1%{?dist}
Summary:        Download Docker images and bundle them into a zip archive

License:        MIT
URL:            https://github.com/shay1987/images2zip
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       docker-ce
Requires:       zip

%description
images2zip reads a list of Docker image references from a text file,
pulls each image, saves it as a tar archive, and creates a zip archive
containing all generated tar files.

Useful for transferring Docker images to air-gapped environments or
creating portable image bundles.

%prep
%setup -q

%build
# Nothing to build - this is a shell script

%install
%make_install PREFIX=%{_prefix}

%files
%license LICENSE
%doc README.md
%{_bindir}/images2zip
%{_mandir}/man1/images2zip.1*

%changelog
* Mon Jan 27 2026 Package Maintainer <maintainer@example.com> - 1.0.0-1
- Initial package release
- Download Docker images from a list file
- Save images as tar archives
- Bundle all tars into a single zip file
- Support for retry logic on pull failures
- Optional cleanup of intermediate tar files
- Verbose and logging modes
