Name:		qubes-template-minimal-stub
Version:	1.1
Release:	1%{?dist}
Summary:	Placeholder package to minimize installed dependencies

Group:		Qubes
License:	GPL
URL:		http://www.qubes-os.org/

Provides:   /usr/bin/mimeopen
Provides:   nautilus-actions
Provides:   gnome-packagekit-updater
Provides:   ImageMagick
Provides:   pycairo
Provides:   notification-daemon
Provides:   desktop-notification-daemon
Provides:   tinyproxy
# Those versions needs to be updated to match target Fedora release, when introducing new one, use ifdefs on %fedora
Provides:   NetworkManager = 0.9.9.0-38
Provides:   pulseaudio = 4.0
Provides:   pulseaudio = 5.0
Provides:   /usr/bin/pulseaudio

%description
Placeholder package, which provide ghost dependencies for qubes-core-vm to
minimize number of packages installed in the minimal template. Note that each
of those dependencies is required for some functionality, so without installing
some real package (minimal replacement?) some functionality will be missing. At least those:
 - graphical updates
 - be a target of qvm-open-in-vm
 - be a DisposableVM template
 - context menu "Send to VM" entry in nautilus
 - graphical notifications
 - sending application icons to dom0 (no fancy icons in dom0 menu)
 - will not work as netvm

%prep


%build

%install

%files

%changelog

