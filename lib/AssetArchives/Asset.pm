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

package MT::Asset;

sub authored_on {
	my $self = shift;
	$self->created_on;
}

sub author {
	undef;
}

sub template_id {
	undef;
}

sub status {
	2;
}

sub title {
	my $self = shift;
	$self->label;
}

sub previous {
	undef;
}

sub next {
	undef;
}

package AssetArchives::Asset;

use warnings;
use strict;

use MT::ArchiveType;
use base qw( MT::ArchiveType );

use MT::Util qw( remove_html encode_html );

sub name {
	return 'Asset';
}

sub archive_label {
	return MT->component('AssetArchives')->translate("ASSET_ADV");
}

sub template_params {
	return {
		entry_archive     => 1,
		archive_template  => 1,
		entry_template    => 1,
		feedback_template => 1,
		archive_class     => "asset-archive",
	};
}

sub archive_file {
	my $obj = shift;
	my ($ctx, %param) = @_;
	my $timestamp = $param{Timestamp};
	my $file_tmpl = $param{Template};
	my $blog      = $ctx->{__stash}{blog};
	my $asset     = $ctx->{__stash}{entry};

	Carp::confess("archive_file_for Asset archive needs an asset")
		unless $asset;

	if ($file_tmpl) {
		$ctx->{__stash}{asset} = $asset;
		$ctx->{current_timestamp} = $asset->created_on;
	}

	'';
}

sub archive_title {
	my $obj = shift;
	encode_html( remove_html( $_[1]->title ) );
}

#sub archive_group_iter {
#	my $obj = shift;
#	my ( $ctx, $args ) = @_;
#
#	my $order =
#	( $args->{sort_order} || '' ) eq 'ascend' ? 'ascend' : 'descend';
#
#	my $blog_id = $ctx->stash('blog')->id;
#	require MT::Asset;
#	my $iter = MT::Asset->load_iter(
#		{
#			blog_id => $blog_id,
#		},
#		{
#			'sort'    => 'created_on',
#			direction => $order,
#			$args->{lastn} ? ( limit => $args->{lastn} ) : ()
#		}
#	);
#	return sub {
#		while ( my $obj = $iter->() ) {
#			return ( 1, assets => [$obj], asset => $obj );
#		}
#		undef;
#	}
#}
#
#sub dynamic_template {
#	'entry/<$MTEntryID$>';
#}

sub archive_entries_count {
    my $self = shift;
	my ($blog, $at, $entry) = @_;

	0;
}

sub default_archive_templates {
	return [
		{
			label => MT->translate('asset_id/index.html'),
			template => '<mt:AssetID />/%i',
            default  => 1,
		},
	];
}

sub entry_based {
	1;
}

sub entry_class {
	['file', 'image', 'audio', 'video'];
}

1;
