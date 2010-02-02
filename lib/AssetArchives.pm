# Copyright (c) 2010 ToI-Planning, All rights reserved.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# $Id$

package AssetArchives;

use strict;
use warnings;

sub init_request {
	my ($cb, $app) = @_;
    my $plugin = $cb->{plugin};

	my @classes = ('file', 'image', 'audio', 'video');

	require MT::Entry;
	require MT::Asset;
	require MT::Template;
	require MT::FileInfo;
	no warnings 'redefine';

	my $load = \&MT::Entry::load;
	*MT::Entry::load = sub {
		my ($class, $args, $cond) = @_;

		if (ref $args eq 'HASH') {
			if (
				(
					ref $args->{'class'}
					&& grep({ my $c = $_; grep($c eq $_, @classes) } @{ $args->{'class'} })
				)
				||
				(
					(! ref $args->{'class'})
					&& grep($args->{'class'} eq $_, @classes)
				)
			) {
				delete($args->{'status'});
				if ($cond->{'sort'} eq 'authored_on') {
					$cond->{'sort'} = 'created_on';
				}
				return MT::Asset->load($args, $cond);
			}
		}
		elsif (ref $args eq 'MT::Asset') {
			return MT::Asset->load({ id => $args->id });
		}

		MT::Object::load(@_);
	};

	my $load_iter = \&MT::Entry::load_iter;
	*MT::Entry::load_iter = sub {
		my ($class, $args, $cond) = @_;

		if (ref $args eq 'HASH') {
			if (
				(
					ref $args->{'class'}
					&& grep({ my $c = $_; grep($c eq $_, @classes) } @{ $args->{'class'} })
				)
				||
				(
					(! ref $args->{'class'})
					&& grep($args->{'class'} eq $_, @classes)
				)
			) {
				delete($args->{'status'});
				if ($cond->{'sort'} eq 'authored_on') {
					$cond->{'sort'} = 'created_on';
				}
				return MT::Asset->load_iter($args, $cond);
			}
		}

		MT::Object::load_iter(@_);
	};

	my $count = \&MT::Entry::count;
	*MT::Entry::count = sub {
		my ($class, $args, $cond) = @_;

		if (ref $args eq 'HASH') {
			if (
				(
					ref $args->{'class'}
					&& grep({ my $c = $_; grep($c eq $_, @classes) } @{ $args->{'class'} })
				)
				||
				(
					(! ref $args->{'class'})
					&& grep($args->{'class'} eq $_, @classes)
				)
			) {
				delete($args->{'status'});
				if ($cond->{'sort'} eq 'authored_on') {
					$cond->{'sort'} = 'created_on';
				}
				return MT::Asset->count($args, $cond);
			}
		}

		MT::Object::count(@_);
	};

	my $context = \&MT::Template::context;
	*MT::Template::context = sub {
		my ($self, $ctx) = @_;

		eval {
			if ($ctx && $ctx->{__stash}{entry}->isa('MT::Asset')) {
				$ctx->{__stash}{asset} = $ctx->{__stash}{entry};
				delete($ctx->{__stash}{entry});
			}
		};

		$context->(@_);
	};

	my $archive_type = \&MT::FileInfo::archive_type;
	*MT::FileInfo::archive_type = sub {
		my ($self, $at) = @_;

		if (
			$at
			&& grep(ucfirst($_) eq $at, @classes)
			&& $self->entry_id
		) {
			$self->asset_id($self->entry_id);
			$self->entry_id(undef);
		}

		MT::Object::archive_type(@_);
	}; 

	{
		my $asset_class = MT->model('asset');
		my $props = $asset_class->properties;
		$props->{child_classes} = {};
		$props->{child_classes}{'MT::FileInfo'} = ();
	}
}

sub asset_post_save {
	my ($cb, $obj, $original) = @_;
	my $app = MT->instance;
	my $blog = $obj->blog
		or return;

	require MT::Util;
	my $res = MT::Util::start_background_task(
		sub {
			$app->run_callbacks('pre_build');
			$app->rebuild_entry(
				Entry             => $obj,
				BuildDependencies => 1,
				OldEntry          => $original,
				OldPrevious       => undef,
				OldNext => undef,
			) or return $app->publish_error();
			$app->run_callbacks('rebuild', $blog);
			$app->run_callbacks('post_build');
			1;
		}
	);

	return 1;
}

1;
