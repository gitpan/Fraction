package Math::Fraction;

# Purpose: To Manipulate Exact Fractions
#
# Copyright 1997 by Kevin Atkinson (kevina@cark.net)
# Version .3a  (8 Mar 1997)
# Alpha Release: Not Very Well Tested
# Developed with Perl v 5.003_37 for Win32.
# Has been testing on Perl Ver 5.003 on a solaris machine.
#
# By using this software you have become an Alpha tester.  By becoming an
# Alpha tester you have agreeded to give be some sort of feedback.
#
# See the files MANUAL and README for more information

require Exporter;
$VERSION = ".3";
@ISA = qw(Exporter);
@EXPORT = qw(frac);
@EXPORT_OK = qw(reduce string decimal num list is_tag);
%EXPORT_TAGS = (
  STR_NUM => [qw(string decimal num)],
);

use Carp;
use strict;

use Math::BigInt;
use Math::BigFloat;

my $DIGITS = undef;

use overload
   "+"   => "add",
   "-"   => "sub",
   "*"   => "mul",
   "/"   => "div",
   "abs" => "abs",
   "**"  => "pow",
   "sqrt"=> "sqrt",
  '""'   => "string",
  "0+"   => "decimal",
  "fallback" => 1;

my @DEF_TAGS = qw(NORMAL REDUCE SMALL);

my %TAGS = (
  NORMAL     => [0, 'NORMAL'],
  MIXED      => [0, 'MIXED'],
  MIXED_RAW  => [0, 'MIXED_RAW'],
  DEF_MIXED  => [0, undef],
  REDUCE     => [1, 'REDUCE'],
  NO_REDUCE  => [1, 'NO_REDUCE'],
  DEF_REDUCE => [1, undef],
  IS_REDUCED => [1, 'IS_REDUCED'],
  SMALL      => [2, 'SMALL'],
  BIG        => [2, 'BIG'],
  DEF_BIG    => [2, undef],
  CONVERTED  => [0, 'CONVERTED'],
);

my @DEF_TAG = qw(DEF_MIXED DEF_REDUCE, DEF_BIG);

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my ($self, @frac, @tags);
  if (&_is_decimal($_[0]) and &_is_decimal($_[1]) and &_is_decimal($_[2]) ) {
      my $sign = $_[0]/abs($_[0]);
      @tags = &_tags(@_[3..$#_]);
      my ($p1, $p2, $p3) = &_fix_num(\@tags, @_[0..2]);
      ($p1, $p2, $p3) = (abs($p1),abs($p2),abs($p3) );
      @frac = &_de_decimal($p1*$p3+$p2, $sign*$p3, \@tags);
  } elsif (&_is_decimal($_[0]) and &_is_decimal($_[1]) ) {
      @tags = &_tags(@_[2..$#_]);
      my ($p1, $p2) = &_fix_num(\@tags, @_[0..1]);
      @frac = &_de_decimal($p1, $p2, \@tags);
      @frac = &_simplify_sign(@frac);
  } elsif (&_is_decimal($_[0]) ) {
      @tags = &_tags(@_[1..$#_]);
      my ($p1) = &_fix_num(\@tags, @_[0]);
      @frac = &_from_decimal($p1);
  } elsif ($_[0] =~ /\s*([\+\-]?)\s*([0-9e\.\+\-]+)\s+([0-9e\.\+\-]+)\s*\/\s*([0-9e\.\+\-]+)/) {
      my $sign = $1.'1';
      @tags = &_tags(@_[1..$#_]);
      my ($p1, $p2, $p3) = &_fix_num(\@tags, $2, $3, $4);
      ($p1, $p2, $p3) = (abs($p1),abs($p2),abs($p3) );
      @frac = &_de_decimal($p1*$p3+$p2, $sign*$p3, \@tags);
  } elsif ($_[0] =~ /\s*([0-9e\.\+\-]+)\s*\/\s*([0-9e\.\+\-]+)/) {
      @tags = &_tags(@_[1..$#_]);
      my ($p1, $p2) = &_fix_num(\@tags, $1, $2);
      @frac = &_de_decimal($p1,$p2, \@tags);
      @frac = &_simplify_sign(@frac);
  } else {
      croak("\"$_[0]\" is of unknown format");
  }
  croak ("Can not have 0 as the denominator") if $frac[1] == 0;

  @frac = &_reduce(@frac) unless &_tag(1, \@tags) eq 'NO_REDUCE';

  $self = [@frac, @tags];
  bless ($self, $class);
  return $self;
}

# The following functions are met to be exported as shortcuts to method
# operations.

sub frac {
  #special exported function to simplify defining fractions
  return Math::Fraction->new(@_);
}

sub modify_default {
  Math::Fraction->modify_tag(@_);
}

# Now are the methodes

sub string {
  my $self = shift;
  my @frac = @{$self}[0..1];
  my @tags = @{$self}[2..$#{$self}];
  my $mixed = &_tag (0, [$_[0]], \@tags );
  if ($mixed eq 'MIXED') {
      @frac = $self->list('MIXED');
      my $string = "";
      $string .= "$frac[0]"           if $frac[0] != 0;
      $string .= " "                  if $frac[0] != 0 and $frac[1] !=0;
      $string .= "$frac[1]/$frac[2]"  if $frac[1] != 0;
      return $string;
  } elsif ($mixed eq 'MIXED_RAW') {
      @frac = $self->list('MIXED');
      return "$frac[0] $frac[1]/$frac[2]";
  } else {
      @frac = $self->list;
      return "$frac[0]/$frac[1]";
  }
}

sub list {
  my $self = shift;
  my @frac = @{$self};
  if ($_[0] eq "MIXED") {
    my $whole=$frac[0]/$frac[1];
    $whole=int($whole) if not ref($frac[0]);
    $frac[0] = $frac[0] - $frac[1]*$whole;
    @frac = ($whole, @frac);
  }
  foreach (@frac) {s/^\+//;};
  return @frac;
}

sub reduce {
  my $self = shift;
  my @frac = @{$self}[0..1];
  my @tags = @{$self}[2 .. $#{$self}];

  return Math::Fraction->new(&_reduce(@frac), @tags);
}


sub decimal {
  my $self = shift;
  my @frac = @{$self};
  return $frac[0]/$frac[1] if not ref($frac[0]);
  return Math::BigFloat->new(Math::BigFloat::fdiv($frac[0], $frac[1], $DIGITS) ) if ref($frac[0]);
}

sub num {
  my $self = shift;
  my @frac = @{$self};
  return $frac[0]/$frac[1] if not ref($frac[0]);
  return Math::BigFloat->new(Math::BigFloat::fdiv($frac[0], $frac[1], $DIGITS) ) if ref($frac[0]);
}

sub is_tag {
  my $self = shift;
  my $tag = shift;
  my $default = 1 if shift eq 'INC_DEF';
  my $is_tag = 0;
  my @tags;
  @tags = @{$self}[2..$#{$self}]  if ref($self);
  @tags = @DEF_TAGS               if $self eq "Math::Fraction";
  {
    $is_tag = 0, last if not $TAGS{$tag};
     my ($num, $tag) = @{$TAGS{$tag}};
    $is_tag = 1    , last if $tags[$num] eq $tag;
    $is_tag = undef, last if $tags[$num] eq undef and not $default;
    $is_tag = -1   , last if $DEF_TAGS[$num] eq $tag
                           and $tags[$num] eq undef and $default;
    $is_tag = 0;
  }
  return $is_tag;
}

sub tags {
  my $self = shift;
  my $inc_def = 1 if shift eq 'INC_DEF';
  my @tags;
  @tags = @{$self}[2..$#{$self}]  if ref($self);
  @tags = @DEF_TAGS               if $self eq "Math::Fraction";
  my $num;
  foreach $num (0 .. $#tags) {
    $tags[$num] = $DEF_TAG[$num]  if $tags[$num] eq undef and not $inc_def;
    $tags[$num] = $DEF_TAGS[$num] if $tags[$num] eq undef and $inc_def;
  }
  return @tags;
}

sub digits {
  my $self = shift;
  return $DIGITS;
}

# All of the modify methods are not meant to return anything, they modify
# the object being referenced too.

sub modify {
  # This method works almost like the new method except that it takes an
  # object as an argement and will modify it instead of creating a new
  # object, also any tags assosated with the object are left in tact
  # unless a new tag is given to override the old.

  my $me = shift;
  my $self;
  my @tags = @{$me}[2..3];
  $self = Math::Fraction->new(@_, @tags, @_);  # The extra @_ is their to override tags
  foreach (0 .. $#{$self}) {$me->[$_]=$self->[$_]}
}

sub modify_digits {
  my $self = shift;
  $DIGITS = shift;
}

sub modify_reduce {
  my $me = shift;
  my $self = $me->reduce;
  foreach (0 .. $#{$self}) {$me->[$_]=$self->[$_]}
}


sub modify_num {
  my $self = shift;
  $self->[0] = $_[0]
}

sub modify_den {
  my $self = shift;
  $self->[1] = $_[0]
}

sub modify_tag {
  my $self = shift;
  if ($self eq "Math::Fraction") {
    @DEF_TAGS = &_tags(@DEF_TAGS,@_);
  } else {  
    my @frac = @{$self}[0..1];
    my @tags = @{$self}[2..$#{$self}];
    @tags = &_tags(@tags,@_);
    $self->[2] =$tags[0];
    $self->[3] =$tags[1];
  }
}

# These methods are meant to be called with the overload operators.

sub add {
  my @frac1 = @{$_[0]};
  my (@frac2, @frac3);
  @frac2 = @{$_[1]}                               if ref($_[1]) eq "Math::Fraction";
  @frac2 = (&_from_decimal($_[1]),'CONVERTED')    if ref($_[1]) ne "Math::Fraction";
  my @tags = &_tags_preserve([@frac1],[@frac2]);

  my $sign1 = &_simplify_sign(@frac1);
  my $sign2 = &_simplify_sign(@frac2);

  if (&_tag(1, \@tags) == 'NO_REDUCE') {
    @frac3 = ($frac1[0]*$frac2[1]+$frac2[0]*$frac1[1],$frac1[1]*$frac2[1]);
    @frac3 = (@frac3, @tags);
  } else {
    # Taken from Knuth v2 (rev 2), p313.
    # It will always return a reduced fraction.
    my $gcd1 = &_gcd($frac1[1],$frac2[1]);
    my $tmp = $frac1[0]*($frac2[1]/$gcd1) + $frac2[0]*($frac1[1]/$gcd1);
    my $gcd2 = &_gcd($tmp,$gcd1);
    @frac3 = ( $tmp/$gcd2, ($frac1[1]/$gcd1)*($frac2[1]/$gcd2) );
    @frac3 = (@frac3, @tags, 'IS_REDUCED');
  }

  return Math::Fraction->new(@frac3);
}

sub sub {
  my ($frac1, $frac2) = ($_[$_[2]], $_[not $_[2]]);  # swap if needed
  $frac1 = Math::Fraction->new($frac1, 'CONVERTED')  if ref($frac1) ne "Math::Fraction";
  $frac2 = Math::Fraction->new($frac2, 'CONVERTED')  if ref($frac2) ne "Math::Fraction";

  $frac2 = Math::Fraction->new($frac2->[0], -$frac2->[1], @{$frac2}[2..$#{$frac2}]);

  return $frac1 + $frac2;
}

sub mul {
  my @frac1 = @{$_[0]};
  my (@frac2, @frac3);
  @frac2 = @{$_[1]}                             if ref($_[1]) eq "Math::Fraction";
  @frac2 = (&_from_decimal($_[1]),'CONVERTED')  if ref($_[1]) ne "Math::Fraction";
  my @tags = &_tags_preserve([@frac1],[@frac2]);

  if (&_tag(1, \@tags) == 'NO_REDUCE') {
    @frac3 = ($frac1[0]*$frac2[0],$frac1[1]*$frac2[1], @tags);
  } else {
    my($gcd1, $gcd2)=(&_gcd($frac1[0],$frac2[1]),&_gcd($frac2[0],$frac1[1]));
    $frac3[0] = ($frac1[0]/$gcd1)*($frac2[0]/$gcd2);
    $frac3[1] = ($frac1[1]/$gcd2)*($frac2[1]/$gcd1);
    @frac3 = (@frac3, @tags, 'IS_REDUCED');
  }
  return Math::Fraction->new(@frac3);
}

sub div {
  my ($frac1, $frac2) = ($_[$_[2]], $_[not $_[2]]);  # swap if needed
  $frac1 = Math::Fraction->new($frac1, 'CONVERTED')  if ref($frac1) ne "Math::Fraction";
  $frac2 = Math::Fraction->new($frac2, 'CONVERTED')  if ref($frac2) ne "Math::Fraction";
         
  $frac2 = Math::Fraction->new($frac2->[1], $frac2->[0], @{$frac2}[2..$#{$frac2}]);
      #Makes a copy of the fraction with the num and den switched.

  return $frac1 * $frac2;
}

sub pow {
  my @frac1;
  @frac1 = @{$_[$_[2]]}                             if ref($_[$_[2]]) eq "Math::Fraction";
  @frac1 = (&_from_decimal($_[$_[2]]),'CONVERTED')  if ref($_[$_[2]]) ne "Math::Fraction";
  my $frac2;
  $frac2 = $_[not $_[2]]->decimal        if ref($_[not $_[2]]) eq "Math::Fraction";
  $frac2 = $_[not $_[2]]                 if ref($_[not $_[2]]) ne "Math::Fraction";
  my @tags = @frac1[2..3];

  my @frac3 = ($frac1[0]**$frac2,$frac1[1]**$frac2);
  @frac3 = (@frac3, @tags );
  return Math::Fraction->new(@frac3);
}

sub sqrt {
  my $self = shift;
  my @frac = @{$self}[0..1];
  my @tags = @{$self}[2..$#{$self}];
  my $ans;
  if ( ref($frac[0]) ) {
    $frac[0] = Math::BigFloat->new( Math::BigFloat::fsqrt($frac[0], $DIGITS) );
    $frac[1] = Math::BigFloat->new( Math::BigFloat::fsqrt($frac[1], $DIGITS) );
    @frac = (@frac, @tags);
  } else {
    @frac = (sqrt($frac[0]) , sqrt($frac[1]), @tags);
  }
  return Math::Fraction->new(@frac);
}


sub abs {
  my $self = shift;
  my @frac = @{$self}[0..1];
  my @tags = @{$self}[2..3];
  return Math::Fraction->new(abs($frac[0]),abs($frac[1]),@tags,'IS_REDUCED');
}


# These function are that functions and not ment to be used as methods

sub _fix_num {
  my $tagsref = shift;
  my @return;
  if (&_tag(2, $tagsref) eq 'BIG') {
    my $num;
    foreach $num (@_) {
      my $ans = Math::BigFloat->new($num);
      push (@return, $ans);
    }
  } else {
    @return = @_
  }
  return @return;
}

sub _is_decimal {
  return $_[0] =~ /^\s*[\+\-0-9e\.]+\s*$/;
}

sub _reduce {
  my @frac = @_;
  my $gcd = &_gcd(@frac);
  return ($frac[0]/$gcd, $frac[1]/$gcd);
}  

sub _simplify_sign {
  my @frac = @_;
  my $sign = 1;
  $sign = ($frac[0]/abs($frac[0]))*($frac[1]/abs($frac[1])) if $frac[0];
  @frac = ($sign*abs($frac[0]), abs($frac[1]) );
  return @frac;
}

sub _tags {
  my @return = (undef, undef);
  my ($NUM, $VALUE) = (0, 1);

  foreach (@_) {
    next if not $TAGS{$_};
    my ($num, $value) = @{$TAGS{$_}};
    $return[$num] = $value;
  }
  return @return;
}


sub _tag {
  my $item = shift;
  my $return;
  foreach (@_, \@DEF_TAGS) {
    last if $return = ${$_}[$item];
  }
  return $return
}

sub _tags_preserve {
  my @frac1 = @{$_[0]};
  my @frac2 = @{$_[1]};
  my @tags;
  if ($frac1[2] eq 'CONVERTED') {
    @tags = @frac2[2 .. $#frac2];
  } elsif ($frac2[2] eq 'CONVERTED') {
    @tags = @frac1[2.. $#frac1];
  } else {
    @tags = map {$frac1[$_] eq $frac2[$_] and $frac1[$_]} (2 .. $#frac1) ;
  }
  return @tags;
}

sub _gcd {
  # Using Euclid's method found in Knuth v2 (rev 2) p320 brought to my
  # attention from the BigInt module

  my ($x, $y) = (abs($_[0]), abs($_[1]));
  if ( ref($x) ) {
    $x = Math::BigInt->new( $x->bgcd($y) );
  } else {
    {
      $x=1, last if $y > 1e17; # If this is so % will thinks its a zero so if
                               # $y>1e17 will simply will basicly give up and
                               # have it return 1 as the GCD.
      my ($x0);
      while ($y != 0) {
        $x0 = $x;
        ($x, $y) = ($y, $x % $y);
        # Note $x0 = $x, $x = $y, $y= $x % $y   Before the Swith
        $x=1, last  if ($x0>99999999 or $x>999999999) and int($x0/$x)*$x+$y != $x0;
        # This is to see if the mod operater through up on us when dealing with
        # large numbers.  If it did set the gcd = 1 and quit.
      }
    }
  }
  return $x;
}

sub _de_decimal {
    my @frac = @_;
    my $big = &_tag(2, $_[2]);
    my @return;
    my (@int_part, @decimal_part);
    if ($big eq "BIG") {
      my @digits = (1,1);
      ($int_part[0], $digits[0]) = $frac[0]->fnorm =~ /(\d+)E\-(\d+)/;
      ($int_part[1], $digits[1]) = $frac[1]->fnorm =~ /(\d+)E\-(\d+)/;
      @digits = sort {$a <=> $b} @digits;
      my $factor = 10**$digits[1];
      @frac = (($_[0]*$factor),($_[1]*$factor));
      chop $frac[0]; chop $frac[1];
      @frac = (Math::BigInt->new($frac[0]), Math::BigInt->new($frac[1]) );
   } else {
      ($int_part[0], $decimal_part[0]) = $frac[0] =~ /(\d+)\.(\d+)/;
      ($int_part[1], $decimal_part[1]) = $frac[1] =~ /(\d+)\.(\d+)/;
      @decimal_part = sort {$a <=> $b} (length($decimal_part[0]),length($decimal_part[1]) );
      my $factor = 10**$decimal_part[1];
      @frac = ($_[0]*$factor, $_[1]*$factor);
   }
   return @frac;
}

sub _from_decimal {
  my $decimal = shift;
  my $big = 'BIG' if ref($decimal);
  my ($repeat, $pat, $pat_len);
  my ($factor, $int_factor, $whole_num, $whole_num_len);
  my ($sign, $int_part, $decimal_part, $decimal_part_len);
  my ($beg_part_len,$beg_part, $other_part, $other_part_len);
  my ($frac1, $frac2, $frac3);

  $decimal =~ s/\s//g;
  ($sign, $int_part, $decimal_part) = $decimal =~ /([\+\-]?)\s*(\d*)\.(\d+)$/;
  $sign .= '1';
  $decimal_part_len = length($decimal_part);
  $int_part = "" unless $int_part;
  $factor = 10**length($decimal_part);
  $int_factor = 10**length($int_part);
  $beg_part_len = 0;
 OuterBlock:
  while ($beg_part_len < $decimal_part_len) {
    $beg_part = substr($decimal_part, 0, $beg_part_len);
    $other_part = substr($decimal_part, $beg_part_len);
    $other_part_len = length($other_part);
    my $i;
    for ($i = 1; $i < ($other_part_len/2+1); $i++) {
      $pat = substr($other_part, 0, $i);
      $pat_len = $i;
      local $_ = $other_part;
      $repeat = undef;
      while (1) {
        ($_) = /^$pat(.*)/;
        my $length = length($_);

        if ( $length <= $pat_len) {
          last unless $length;
          my $sub_pat = substr($pat, 0, $length);
          $repeat=1 ,last OuterBlock if $sub_pat eq $_;
          if ($sub_pat eq $_ - 1) {
           # this is needed to see if it really is the repeating fracton
           # we intented it to be.  If we don't do this 1.1212 would become
           # 1120/999 = 1.1211211211.
           # The first three lines converts it to a fraction and the
           # rests tests it to the actual repeating decimal/
           # The NO_REDUCE flag is their to save time as reducing large
           # fraction can take a bit of time which is unnecessary as we will
           # be converting it to a decimal.
          $frac1 = Math::Fraction->new($beg_part+0,10**$beg_part_len, 'NO_REDUCE', $big);
          $frac2 = Math::Fraction->new($pat+0,"9"x$pat_len*10**$beg_part_len, 'NO_REDUCE', $big);
          $frac3 = $frac1 + $frac2;
          my $what_i_get = $frac3->decimal;
          $decimal_part = Math::BigFloat->new($decimal_part) if $big;
          my $what_i_should_get = (($decimal_part-1)/$factor)."$pat"x($DIGITS+20);
           # the -1 is to get rid of the rounding thus .6667 would
           # become .6666 and then we tack on what the apparent pattern
           # should be until perl will no longer care (ie out of its
           # floating point presion range)
#          print "what: $what_i_get $what_i_should_get ($int_part)\n";
          $repeat=1, last OuterBlock if $what_i_get == $what_i_should_get;
          }
        }
      }
    }
    $beg_part_len++;
  }

  if ($repeat) {
    $frac1 = Math::Fraction->new($beg_part+0,10**$beg_part_len, $big);
    $frac2 = Math::Fraction->new($pat+0,"9"x$pat_len*10**$beg_part_len, $big);
    $frac3 = $sign*($int_part + $frac1 + $frac2);
    return @{$frac3}[0 .. 1];
  } else {
    return ($decimal*$factor,$factor, $big);
  }
}

1;
