package PERLANCAR::Module::List;

# DATE
# VERSION

#IFUNBUILT
use strict;
use warnings;
#END IFUNBUILT

sub list_modules($$) {
	my($prefix, $options) = @_;
	my $trivial_syntax = $options->{trivial_syntax};
	my($root_leaf_rx, $root_notleaf_rx);
	my($notroot_leaf_rx, $notroot_notleaf_rx);
	if($trivial_syntax) {
		$root_leaf_rx = $notroot_leaf_rx = qr#:?(?:[^/:]+:)*[^/:]+:?#;
		$root_notleaf_rx = $notroot_notleaf_rx =
			qr#:?(?:[^/:]+:)*[^/:]+#;
	} else {
		$root_leaf_rx = $root_notleaf_rx = qr/[a-zA-Z_][0-9a-zA-Z_]*/;
		$notroot_leaf_rx = $notroot_notleaf_rx = qr/[0-9a-zA-Z_]+/;
	}
	die "bad module name prefix `$prefix'"
		unless $prefix =~ /\A(?:${root_notleaf_rx}::
					 (?:${notroot_notleaf_rx}::)*)?\z/x &&
			 $prefix !~ /(?:\A|[^:]::)\.\.?::/;
	my $list_modules = $options->{list_modules};
	my $list_prefixes = $options->{list_prefixes};
	my $list_pod = $options->{list_pod};
	my $use_pod_dir = $options->{use_pod_dir};
	return {} unless $list_modules || $list_prefixes || $list_pod;
	my $recurse = $options->{recurse};
	my $return_path = $options->{return_path};
	my @prefixes = ($prefix);
	my %seen_prefixes;
	my %results;
	while(@prefixes) {
		my $prefix = pop(@prefixes);
		my @dir_suffix = split(/::/, $prefix);
		my $module_rx =
			$prefix eq "" ? $root_leaf_rx : $notroot_leaf_rx;
		my $pm_rx = qr/\A($module_rx)\.pmc?\z/;
		my $pod_rx = qr/\A($module_rx)\.pod\z/;
		my $dir_rx =
			$prefix eq "" ? $root_notleaf_rx : $notroot_notleaf_rx;
		$dir_rx = qr/\A$dir_rx\z/;
		foreach my $incdir (@INC) {
			my $dir = join("/", $incdir, @dir_suffix);
			opendir(my $dh, $dir) or next;
			while(defined(my $entry = readdir($dh))) {
				if(($list_modules && $entry =~ $pm_rx) ||
						($list_pod &&
							$entry =~ $pod_rx)) {
					$results{$prefix.$1} = $return_path ? "$dir/$entry" : undef;
				} elsif(($list_prefixes || $recurse) &&
						($entry ne '.' && $entry ne '..') &&
						$entry =~ $dir_rx &&
						-d join("/", $dir,
							$entry)) {
					my $newpfx = $prefix.$entry."::";
					next if exists $seen_prefixes{$newpfx};
					$results{$newpfx} = $return_path ? "$dir/$entry/" : undef
						if $list_prefixes;
					push @prefixes, $newpfx if $recurse;
				}
			}
			next unless $list_pod && $use_pod_dir;
			$dir = join("/", $dir, "pod");
			opendir($dh, $dir) or next;
			while(defined(my $entry = readdir($dh))) {
				if($entry =~ $pod_rx) {
					$results{$prefix.$1} = undef;
				}
			}
		}
	}
	return \%results;
}

1;
# ABSTRACT: Like Module::List, but with lower startup overhead

=for Pod::Coverage .+

=head1 DESCRIPTION

This module is a fork of L<Module::List> 0.003. It's exactly like Module::List,
except for the following differences:

=over

=item * lower startup overhead (with some caveats)

It strips the usage of L<Exporter>, L<IO::Dir>, L<Carp>, L<File::Spec>, with the
goal of saving a few milliseconds (a casual test on my PC results in 11ms vs
39ms).

Path separator a hard-coded C</>.

=item * Recognize C<return_path> option

Normally the returned hash has C<undef> as the values. With this option set to
true, the values will contain the path instead. Useful if you want to collect
all the paths, instead of having to use L<Module::Path> or L<Module::Path::More>
for each module again.

=back


=head1 SEE ALSO

L<Module::List>
