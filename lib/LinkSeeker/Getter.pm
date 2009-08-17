package LinkSeeker::Getter;

use Any::Moose;

extends "LinkSeeker::SubClassBase";

has store => (is => 'rw', default => '');

1;
